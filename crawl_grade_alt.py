#!/usr/bin/env python3
import argparse
import re
import os
import sys
from bs4 import BeautifulSoup

def clean_text(text):
    """Clean up text by removing extra whitespace and converting to proper encoding."""
    if text is None:
        return ""
    return ' '.join(text.strip().split())

def extract_grades_from_html(html_file):
    """Extract grade information from the HTML file."""
    try:
        with open(html_file, 'r', encoding='utf-8') as file:
            content = file.read()
    except UnicodeDecodeError:
        with open(html_file, 'r', encoding='latin-1') as file:
            content = file.read()
    
    soup = BeautifulSoup(content, 'html.parser')
    
    table = soup.find('table', id='tblStudentMark')
    if not table:
        table = soup.find('table', {'id': 'grdGrades'})  
    
    if not table:
        tables = soup.find_all('table', {'class': ['tableborder', 'gridview', 'DataGrid']})
        if tables:
            table = max(tables, key=lambda t: len(t.find_all('tr')))
    
    if not table:
        tables = soup.find_all('table')
        for t in tables:
            headers = [clean_text(th.get_text()) for th in t.find_all('th')] + \
                     [clean_text(td.get_text()) for td in t.find_all('td', {'class': 'cssListHeader'})]
            
            grade_keywords = ['Mã học phần', 'Tên học phần', 'Số TC', 'Điểm', 'TKHP']
            if any(keyword in ' '.join(headers) for keyword in grade_keywords):
                table = t
                break
    
    if not table:
        print("Could not find the grades table in the HTML file.")
        return []
    
    rows = table.find_all('tr')
    if not rows:
        print("No rows found in the grades table.")
        return []
    
    grades = []
    current_term = None
    
    for row in rows[1:]: 
        cells = row.find_all('td')
        
        if len(cells) < 5:  
            continue
        
        term_text = clean_text(cells[0].get_text())
        if "Học kỳ" in term_text:
            match = re.search(r'Học kỳ (\d+)', term_text)
            if match:
                current_term = int(match.group(1))
            continue
        
        for cell in cells:
            cell_text = clean_text(cell.get_text())
            if "Học kỳ" in cell_text:
                match = re.search(r'Học kỳ (\d+)', cell_text)
                if match:
                    current_term = int(match.group(1))
        
        try:
            header_row = rows[0]
            header_cells = header_row.find_all('td') or header_row.find_all('th')
            header_texts = [clean_text(cell.get_text()) for cell in header_cells]
            
            column_map = {
                'stt': next((i for i, h in enumerate(header_texts) if 'STT' in h), 0),
                'code': next((i for i, h in enumerate(header_texts) if 'Mã' in h and 'học phần' in h), 1),
                'name': next((i for i, h in enumerate(header_texts) if 'Tên' in h and 'học phần' in h), 2),
                'credits': next((i for i, h in enumerate(header_texts) if 'Số TC' in h or 'tín chỉ' in h), 3)
            }
            
            grade_keywords = ['TKHP', 'Điểm tổng kết', 'Điểm TK', 'Điểm HP']
            for keyword in grade_keywords:
                try:
                    grade_idx = next((i for i, h in enumerate(header_texts) if keyword in h), None)
                    if grade_idx is not None:
                        column_map['grade'] = grade_idx
                        break
                except StopIteration:
                    continue
            
            if 'grade' not in column_map:
                for i, cell in enumerate(cells):
                    text = clean_text(cell.get_text())
                    if text and text.replace('.', '', 1).isdigit():
                        try:
                            value = float(text)
                            if 0 <= value <= 10: 
                                column_map['grade'] = i
                                break
                        except ValueError:
                            continue
            
            if 'grade' not in column_map:
                column_map['grade'] = 9 
            
            if len(cells) > max(column_map.values()):
                stt = clean_text(cells[column_map['stt']].get_text())
                course_code = clean_text(cells[column_map['code']].get_text())
                course_name = clean_text(cells[column_map['name']].get_text())
                credits = clean_text(cells[column_map['credits']].get_text())
                grade_10_scale = clean_text(cells[column_map['grade']].get_text())
                
                if not grade_10_scale or not grade_10_scale.replace('.', '', 1).isdigit():
                    continue
                
                try:
                    stt = int(stt) if stt.isdigit() else 0
                    credits = int(credits) if credits.isdigit() else 0
                    grade_10_scale = float(grade_10_scale)
                    
                    grades.append({
                        'STT': stt,
                        'HocKi': current_term,
                        'MaHocPhan': course_code,
                        'TenHocPhan': course_name,
                        'SoTC': credits,
                        'TKHP': grade_10_scale
                    })
                except (ValueError, TypeError) as e:
                    print(f"Error processing row: {e}")
                    continue
        except (IndexError, StopIteration) as e:
            print(f"Error identifying columns: {e}")
            continue
    
    return grades

def generate_sql_script(grades, output_file):
    """Generate SQL script to insert or update grades in the database using ON DUPLICATE KEY UPDATE."""
    with open(output_file, 'w', encoding='utf-8') as file:
        file.write("-- Auto-generated SQL script for grade insertion/update\n")
        file.write("-- Generated by crawl_grade.py\n")
        file.write("-- Using ON DUPLICATE KEY UPDATE syntax with alias (to avoid deprecated VALUES function)\n\n")
        
        file.write("START TRANSACTION;\n\n")
        
        for grade in grades:
            file.write(f"""-- Insert or update {grade['MaHocPhan']} - {grade['TenHocPhan']}
INSERT INTO Grades (MaHocPhan, TenHocPhan, SoTC, TKHP, HocKi)
VALUES (
    '{grade['MaHocPhan']}',
    '{grade['TenHocPhan']}',
    {grade['SoTC']},
    {grade['TKHP']},
    {grade['HocKi'] if grade['HocKi'] is not None else 'NULL'}
) AS new_values
ON DUPLICATE KEY UPDATE
    TenHocPhan = new_values.TenHocPhan,
    SoTC = new_values.SoTC,
    TKHP = new_values.TKHP,
    HocKi = new_values.HocKi;
""")
        
        file.write("COMMIT;\n")
    
    print(f"SQL script generated: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='Crawl grades from HTML file and generate SQL script using ON DUPLICATE KEY UPDATE.')
    parser.add_argument('-i', '--input', dest='input_file', required=True, help='HTML file containing grades')
    parser.add_argument('-o', '--output', default='gpa_insert.sql', help='Output SQL file (default: gpa_insert.sql)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Print verbose output')
    parser.add_argument('-s', '--sql-style', choices=['simple', 'duplicate-key'], default='duplicate-key',
                      help='SQL generation style: simple inserts or ON DUPLICATE KEY UPDATE (default: duplicate-key)')
    parser.add_argument('-f', '--force', action='store_true', help='Force overwrite existing output file')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input_file):
        print(f"Error: Input file '{args.input_file}' not found.")
        sys.exit(1)
    
    if os.path.exists(args.output) and not args.force:
        response = input(f"Output file '{args.output}' already exists. Overwrite? (y/n): ")
        if response.lower() != 'y':
            print("Operation cancelled.")
            sys.exit(0)
    
    if args.verbose:
        print(f"Processing HTML file: {args.input_file}")
        print(f"SQL style: {args.sql_style}")
    
    grades = extract_grades_from_html(args.input_file)
    
    if grades:
        print(f"Found {len(grades)} grade records.")
        
        if args.sql_style == 'simple':
            try:
                from crawl_grade import generate_sql_script as generate_simple_sql
                generate_simple_sql(grades, args.output)
            except ImportError:
                print("Warning: Could not import simple INSERT function. Using ON DUPLICATE KEY UPDATE.")
                generate_sql_script(grades, args.output)
        else:
            generate_sql_script(grades, args.output)
    else:
        print("No grade records found. Check the HTML file format.")
        print("Try using clean_html.py first to prepare the HTML file:")
        print(f"    python clean_html.py -i {args.input_file} -o cleaned_{os.path.basename(args.input_file)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
