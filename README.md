# GPA Calculator

Cuz my school web suck so I made this.

## Requirements

- Docker and Docker Compose for the database and web interface
- Python 3.6+ (for the data import tools only)
- BeautifulSoup4 (for the data import tools only) or you can install from venv

## System Setup

### 1. Install the requirement

You can use whatever method you want, but to keep this straight I'll show how to do it using venv.
Run the command below to create a local virtual enviroment.

```bash
python3 -m venv .venv
```

After the virtual environment was created, we have to activate it throught this command.

```bash
source .venv/bin/activate
```

Then run this command to install the required package.

```bash
pip install requirements.txt
```

### 2. Start the Database and Web Interface

The system uses Docker to run MySQL and phpMyAdmin:

```bash
# Start the containers
docker-compose up -d
```

This will start:

- MySQL container for storing grade data
- phpMyAdmin container for web-based database management


### 3. Access the Web Interface

Once the containers are running, you can access phpMyAdmin at:

- URL: [http://localhost:8080](http://localhost:8080) (or the port configured in your docker-compose.yml)
- Username: root
- Password: 123 (or as configured in your docker-compose.yml)

### Importing Grades into MySQL via Command Line

After generating your SQL file using the import tools, you can import it directly into the MySQL container:

#### PowerShell (Windows)

```powershell
Get-Content gpa_insert.sql | docker exec -i mysql mysql -u root -p123 --default-character-set=utf8mb4 GPA
```

#### Linux/Mac

```bash
docker exec -i mysql mysql -u root -p123 --default-character-set=utf8mb4 GPA < gpa_insert.sql
```

## Grade Import Tools Usage

The following tools help you import grade data from HTML grade reports into the database. These are optional utilities to make data entry easier.

All commands support the `-h` or `--help` flag to display detailed usage information:

```bash
python clean_html.py --help
python crawl_grade.py --help
python crawl_grade_alt.py --help
```

### Step 1: Clean the HTML (Optional but Recommended)

The `clean_html.py` script helps extract and clean the grade table from the raw HTML:

```bash
python clean_html.py -i INPUT_HTML_FILE -o OUTPUT_HTML_FILE [-f FORMAT] [-v] [--force]
```

For complete options, use the help flag: `python clean_html.py --help`

Example:

```bash
python clean_html.py -i raw_grades.html -o clean_grades.html -f full -v
```

### Step 2: Extract Grades and Generate SQL

Use a single tool with options to control the SQL generation style:

```bash
python crawl_grade.py -i INPUT_HTML_FILE [-o OUTPUT_SQL_FILE] [-s SQL_STYLE] [-v] [-f]
```

Key Arguments:

- `-i`, `--input`: Path to the HTML file (cleaned or raw)
- `-o`, `--output`: Path to the output SQL file
- `-s`, `--sql-style`: SQL generation style ('simple' or 'duplicate-key')

For complete options, use the help flag: `python crawl_grade.py --help`

Example for simple INSERT statements:

```bash
python crawl_grade.py -i clean_grades.html -o simple_insert.sql -s simple -v
```

Example for INSERT with ON DUPLICATE KEY UPDATE:

```bash
python crawl_grade.py -i clean_grades.html -o upsert_grades.sql -s duplicate-key -v
```

Alternative: You can also use the specialized script for ON DUPLICATE KEY UPDATE:

```bash
python crawl_grade_alt.py -i INPUT_HTML_FILE [-o OUTPUT_SQL_FILE] [-v] [-f]
```

### Complete Workflow Example

```bash
# Step 1: Clean the HTML
python clean_html.py -i gpa.html -o clean_grades.html -f full -v

# Step 2: Extract grades and generate SQL (choose one approach)
# Simple INSERT statements:
python crawl_grade.py -i clean_grades.html -o gpa_insert.sql -s simple -v

# OR: INSERT with ON DUPLICATE KEY UPDATE:
python crawl_grade.py -i clean_grades.html -o gpa_insert.sql -s duplicate-key -v

# Step 3: Import the SQL script into your MySQL database
# For PowerShell:
# Get-Content gpa_insert.sql | docker exec -i mysql mysql -u root -p123 --default-character-set=utf8mb4 GPA
# For Linux/Mac:
# docker exec -i mysql mysql -u root -p123 --default-character-set=utf8mb4 GPA < gpa_insert.sql

# Step 4: Access the database via phpMyAdmin to view and analyze GPA results
# Open your browser and navigate to http://localhost:8080
```

## Features

- **GPA Calculation System**:
  - Stores and manages student grades in a MySQL database
  - Automatically calculates GPA in multiple formats (4.0 scale, letter grades)
  - Containerized deployment for easy setup

- **Grade Import Tools**:
  - Extract grades from HTML grade reports
  - Generate SQL statements to insert or update grades in the database
  - Two SQL generation styles available:
    1. Simple INSERT statements (default)
    2. INSERT with ON DUPLICATE KEY UPDATE statements (alternative version)
  - Sets the semester (HocKi) field appropriately for all courses
  - Handles different HTML structures and encodings

## Database Structure and Configuration

1. The system uses the database structure defined in `GPA.sql`, which includes:
   - `Grades` table with fields: STT, HocKi, MaHocPhan, TenHocPhan, SoTC, TKHP, TKHP_He4, TKHP_HeChu
   - Triggers that automatically calculate TKHP_He4 and TKHP_HeChu values
   - Various functions and procedures for GPA calculations

2. When setting up the system for the first time, the database schema is automatically created if you're using the provided docker-compose setup. If needed, you can manually create it with:

   ```bash
   docker exec -i mysql mysql -u root -p123 --default-character-set=utf8mb4 < GPA.sql
   ```

3. The grade import tool preserves the semester (HocKi) information from the HTML file. If the semester cannot be determined, it will be set to NULL in the SQL script.

4. For the ON DUPLICATE KEY UPDATE approach, make sure your `Grades` table has `MaHocPhan` set as a unique key or primary key. If it's not, you can add it using phpMyAdmin or with:

   ```sql
   ALTER TABLE Grades ADD UNIQUE INDEX idx_mahocphan (MaHocPhan);
   ```

5. The database triggers will automatically calculate the TKHP_He4 and TKHP_HeChu values based on the TKHP value, so you don't need to provide these values in the SQL script.

6. The simple INSERT script temporarily disables foreign key checks to allow for easier inserts. This is automatically re-enabled at the end of the transaction.

### SQL Output Options

#### 1. Simple INSERT Statements

Generated with `-s simple` option:

```sql
-- Insert or update CS101 - Introduction to Computer Science
INSERT INTO Grades (HocKi, MaHocPhan, TenHocPhan, SoTC, TKHP)
VALUES (
    1,
    'CS101',
    'Introduction to Computer Science',
    3,
    8.5
);
```

#### 2. ON DUPLICATE KEY UPDATE

Generated with `-s duplicate-key` option:

```sql
-- Insert or update CS101 - Introduction to Computer Science
INSERT INTO Grades (MaHocPhan, TenHocPhan, SoTC, TKHP, HocKi)
VALUES (
    'CS101',
    'Introduction to Computer Science',
    3,
    8.5,
    1
) AS new_values
ON DUPLICATE KEY UPDATE
    TenHocPhan = new_values.TenHocPhan,
    SoTC = new_values.SoTC,
    TKHP = new_values.TKHP,
    HocKi = new_values.HocKi;
```

**Note:** For the ON DUPLICATE KEY UPDATE approach to work correctly, the `MaHocPhan` column in your database should have a unique index or be defined as a primary key.

## Advanced Usage

### Handling Different HTML Formats

If you encounter issues with a specific HTML file format, try different cleaning options:

```bash
# Extract just the table
python clean_html.py -i problematic.html -o cleaned.html -f table-only -v

# Keep the full HTML structure but clean it
python clean_html.py -i problematic.html -o cleaned.html -f full -v
```

### Manual Database Management

After generating the SQL file, you might want to review it before execution:

1. Open the generated SQL file in a text editor
2. Verify the records to be inserted or updated
3. Execute the script in your MySQL database:

```bash
mysql -u username -p GPA < gpa_insert.sql
```

### One-Line Command for Complete Processing

Process everything in one line:

```bash
# Clean the HTML and generate SQL in one command
python clean_html.py -i original.html -o cleaned.html -v && python crawl_grade.py -i cleaned.html -o grades.sql -s simple -v
```

## Troubleshooting

- **Docker Issues**: If you have problems with Docker containers, check logs with `docker logs mysql` or `docker logs phpmyadmin`
- **HTML Parsing Issues**: If the import script can't find the grades table, try using the clean_html.py script with different format options
- **SQL Execution Errors**: Check that your MySQL server allows the SET FOREIGN_KEY_CHECKS=0 command
- **Duplicate Key Errors**: With the simple INSERT script, you might get duplicate key errors if you're inserting records that already exist. In this case, use the `-s duplicate-key` option
- **Character Encoding Issues**: If you see strange characters in the SQL output, try specifying a different encoding when reading the HTML file
- **MySQL Warnings**: If you get a warning about `VALUES function is deprecated`, make sure you're using the latest version of the import tools which use the recommended alias syntax
