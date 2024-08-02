



import sys
import os

def bin_to_mi(bin_file, mi_file):
    with open(bin_file, 'rb') as bf, open(mi_file, 'w') as mf:
        while byte := bf.read(1):
            mf.write(f'{ord(byte):02X}\n')



if __name__ == '__main__':
    if len(sys.argv) == 3:
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        if not os.path.exists(input_file):
            print(f'Error: {input_file} does not exist')
            exit(1)
        if os.path.exists(output_file):
            print(f'Overwrite {output_file}? (y/n)')
            choice = input().lower()
            if choice != 'y':
                print('Exiting...')
                exit(0)
        

        bin_to_mi(input_file, output_file)
        print(f'{input_file} converted to {output_file}')
    else:
        print('Usage: python bin_to_mi.py <bin_file> <mi_file>')
