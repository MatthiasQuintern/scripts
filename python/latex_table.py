"""
converts a csv into Latex code, cell by cell

http://users.ph.tum.de/ge75yag/
Matthias Quintern
2021
This software comes with no warranty.
"""

from sys import argv

# path to the csv file must be the first sys argv
try:
    csv_filepath = argv[1]
except IndexError:
    # comment 'exit(1)' and put your file path below if you are using this script from an IDE
    csv_filepath = "PUT YOUR PATH HERE"
    print("No csv_filepath specified. Usage: 'python3 path_to_this_script path_to_your_csv'")
    exit(1)

# if a separator is specified as second argument
try:
    separator = argv[2]
except IndexError:
    print("No separator given. Assuming csv separator=','")
    separator = ","

string = ""

try:
    with open(csv_filepath, "r") as file:
        for line in file:
            line_list = line.split(separator)
            for i in range(len(line_list)):
                string += "$" + line_list[i].replace("\n", "") + "$"
                # the '&' character should not be added after last column
                if i + 1 < len(line_list):
                    string += "\t& "
            string += "\t" + r"\\ \hline" + "\n"

except FileNotFoundError:
    print(f"FileNotFoundError: Can not find {csv_filepath}")
    exit(1)
except PermissionError:
    print(f"PermissionError: Permission denied to open {csv_filepath}. Try as superuser or change permissions for the file.")
    exit(1)

# if a filepath is specified as third argument, the string will be saved in the file
# CAUTION: If a file with that name already exists, all content of that file will be lost!
try:
    txt_filepath = argv[3]
    with open(txt_filepath, "w") as txt_file:
        txt_file.write(string)
except IndexError:
    print("No filepath given -> Output will not be saved")
except Exception:
    print("An unknown Exception occured while trying to write the output into a file.")

# print the end result to the console
print(string)

exit(0)
