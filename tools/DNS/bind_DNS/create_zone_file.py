import sys

DOMAIN    = sys.argv[1]
USER      = sys.argv[2]
FILE_PATH = f'/etc/bind/{DOMAIN}'

print(f"DOMAIN: {DOMAIN}")
print(f"USER: {USER}")


class ReadExcel():
    def __init__(self, excel_path):
        self.excel_path = excel_path

    def read_lines(self):
        registry_file = open('./tools/DNS/registry.csv', 'r')
        file_lines = registry_file.readlines()

        return file_lines

    def split_cells(self, file_lines):

        lines_with_cells = []

        for file_line in file_lines:
            line_cells = file_line.strip().split(";")
            lines_with_cells.append(line_cells)

        return lines_with_cells


class CreateBind():
    def __init__(self, lines_with_cells):
        self.lines_with_cells = lines_with_cells
        self.ns_in_domain_lines = []
        self.address_lines = []
        self.file_content = f"""
$TTL 38400  ; Tiempo (seg) de vida por defecto (TTL)
{DOMAIN}. IN SOA ns1.{DOMAIN}. {USER}.{DOMAIN}. (
    2023110701 ; Serial
    10800      ; Refresh
    3600       ; Retry
    604800     ; Expire
    38400      ; Minimum TTL
)
"""

    def detect_registry_type(self):

        for line in self.lines_with_cells:
            if line[1] == 'A':
                self.a_registry(line)
            elif line[1] == 'NS':
                self.ns_registry(line)
                self.a_registry(line)
            elif line[1] == 'MX':
                self.a_registry(line)
                self.mx_registry(line)

    def ns_registry(self, line):

        line_content = ""

        line_content = f"{DOMAIN}. IN NS {line[0]}.{DOMAIN}."

        self.ns_in_domain_lines.append(line_content)

        print(f"\033[33mNS REGISTRY CREATED: \033[0m {line[0]}.{DOMAIN}")

    def a_registry(self, line):

        line_content = ""
        # NS1 == DNS SERVER
        if line[0] == "ns1":

            line_content = f"{DOMAIN}. IN A {line[2]}\n"

        line_content += f"{line[0]}.{DOMAIN}. IN A {line[2]}"

        self.address_lines.append(line_content)

        print(f"\033[33mADDRESS REGISTRY CREATED: \033[0m {line[0]}.{DOMAIN} \033[33mIP: \033[0m {line[2]}")

    def mx_registry(self, line):

        line_content = ""
        # Solo registro MX tiene la prioridad al final
        priority = line[3]
        # cuanto mas bajo el numero, mas prioridad
        line_content += f"@            IN MX {priority} {line[0]}.{DOMAIN}.\n"
        line_content += f"autodiscover IN CNAME         {line[0]}.{DOMAIN}.\n"
        line_content += f"autoconfig   IN CNAME         {line[0]}.{DOMAIN}."

        self.ns_in_domain_lines.append(line_content)

        print(f"\033[33mMAIL REGISTRY CREATED: \033[0m @{line[0]}.{DOMAIN} \033[33mPRIORITY: \033[0m {priority}")

    def create_file_content(self):

        for line in self.ns_in_domain_lines:
            self.file_content += f"{line}\n"

        for line in self.address_lines:
            self.file_content += f"{line}\n"

        return self.file_content

    def write_file(self, file_content, FILE_PATH):
        bind_file = open(FILE_PATH, 'w+')
        bind_file.write(file_content)


def main():

    read_excel = ReadExcel('../registry.csv')
    file_lines = read_excel.read_lines()
    lines_with_cells = read_excel.split_cells(file_lines)

    create_bind = CreateBind(lines_with_cells)
    create_bind.detect_registry_type()

    file_content = create_bind.create_file_content()
    create_bind.write_file(file_content, FILE_PATH)

    print("\033[92mMASTER ZONE CORRECTLY CREATED\033[0m")
    print(f"ZONE FILE PATH: {FILE_PATH}")


main()
