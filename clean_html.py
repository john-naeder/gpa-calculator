import os
import re
import sys
import argparse
from bs4 import BeautifulSoup

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='Clean HTML grade file by extracting only the grade table')
    parser.add_argument('-i', '--input-file', help='Path to the input HTML file', required=True)
    parser.add_argument('-o', '--output-file', help='Path to the output HTML file', required=True)
    parser.add_argument('-f', '--format', choices=['full', 'table-only'], default='table-only',
                       help='Output format: full HTML or table-only (default: table-only)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Print verbose output')
    parser.add_argument('--force', action='store_true', help='Force overwrite existing output file')
    
    return parser.parse_args()

def clean_html(input_file, output_file, format_type='table-only'):
    """Extract grade table from HTML file and save to a new file"""
    try:
        try:
            with open(input_file, 'r', encoding='utf-8') as file:
                content = file.read()
        except UnicodeDecodeError:
            with open(input_file, 'r', encoding='latin-1') as file:
                content = file.read()
        
        soup = BeautifulSoup(content, 'html.parser')
        
        grade_table = soup.find('table', {'id': 'tblStudentMark'})
        
        if not grade_table:
            for table_id in ['grdGrades', 'dgResults', 'tblStudentMark', 'ctl00_ContentPlaceHolder1_grdStudentMark']:
                grade_table = soup.find('table', {'id': table_id})
                if grade_table:
                    break
        
        if not grade_table:
            tables = soup.find_all('table', {'class': ['tableborder', 'gridview', 'DataGrid']})
            if tables:
                grade_table = max(tables, key=lambda t: len(t.find_all('tr')))
        
        if not grade_table:
            tables = soup.find_all('table')
            for t in tables:
                headers = [h.get_text().strip() for h in t.find_all('th')] + \
                          [td.get_text().strip() for td in t.find_all('td', {'class': 'cssListHeader'})]
                
                grade_keywords = ['Mã học phần', 'Tên học phần', 'Số TC', 'Điểm', 'TKHP']
                if any(keyword in ' '.join(headers) for keyword in grade_keywords):
                    grade_table = t
                    break
        
        if not grade_table:
            print("Error: Grade table not found in the input HTML file")
            return False
        
        if format_type == 'table-only':
            new_soup = BeautifulSoup('<html><body></body></html>', 'html.parser')
            new_soup.body.append(grade_table)
            
            with open(output_file, 'w', encoding='utf-8') as file:
                file.write(str(new_soup))
        else:
            for script in soup(["script", "style"]):
                script.decompose()
                
            for tag in soup.find_all(True):
                attrs_to_remove = []
                for attr in tag.attrs:
                    if attr not in ['id', 'class', 'src', 'href']:
                        attrs_to_remove.append(attr)
                for attr in attrs_to_remove:
                    del tag[attr]
            
            if grade_table:
                grade_table['style'] = 'border: 2px solid red; background-color: #f9f9f9;'
            
            # Write the full cleaned HTML
            with open(output_file, 'w', encoding='utf-8') as file:
                file.write(str(soup))
        
        print(f"Successfully extracted grade table and saved to {output_file}")
        return True
    
    except Exception as e:
        print(f"Error cleaning HTML: {e}")
        return False

def main():
    """Main function"""
    args = parse_arguments()
    
    if not os.path.exists(args.input_file):
        print(f"Error: Input file '{args.input_file}' not found.")
        sys.exit(1)
    
    if os.path.exists(args.output_file) and not args.force:
        response = input(f"Output file '{args.output_file}' already exists. Overwrite? (y/n): ")
        if response.lower() != 'y':
            print("Operation cancelled.")
            sys.exit(0)
    
    if args.verbose:
        print(f"Input file: {args.input_file}")
        print(f"Output file: {args.output_file}")
        print(f"Format: {args.format}")
    
    # Clean the HTML
    success = clean_html(args.input_file, args.output_file, args.format)
    
    if success:
        print("HTML cleaning completed successfully.")
    else:
        print("HTML cleaning failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
