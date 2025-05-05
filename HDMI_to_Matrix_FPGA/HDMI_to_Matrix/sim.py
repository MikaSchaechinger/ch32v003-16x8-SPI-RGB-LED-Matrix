import os
import subprocess
import sys

# Konfiguration
source_folder = "src"
output_folder = "sim"
object_folder = "objects"

# Hilfsfunktionen
def find_testbenches():
    testbenches = {}
    for root, _, files in os.walk(source_folder):
        for file in files:
            if file.endswith("_tb.v") or file.endswith("_tb.sv"):
                name = os.path.splitext(file)[0]
                path = os.path.join(root, file)
                testbenches[name] = path
    return testbenches

def collect_source_files():
    sources = []
    for root, _, files in os.walk(source_folder):
        for file in files:
            if file.endswith(".v") or file.endswith(".sv"):
                if "_defines.v" in file:
                    continue
                full_path = os.path.join(root, file)
                with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    if 'pragma protect' not in content:
                        if not file.endswith('_tb.v') and not file.endswith('_tb.sv'):
                            sources.append(full_path)
    return sources

def ensure_directories():
    os.makedirs(os.path.join(output_folder, object_folder), exist_ok=True)

def compile_and_run(testbench_name, testbench_path, sources):
    obj_file = os.path.join(output_folder, object_folder, f"{testbench_name}.o")

    # Alte Datei löschen
    if os.path.exists(obj_file):
        os.remove(obj_file)

    # Kompilieren
    cmd = ["iverilog", "-g2012", "-o", obj_file, "-s", testbench_name] + sources + [testbench_path]
    print("Compiling:", ' '.join(cmd))
    result = subprocess.run(cmd)

    if os.path.exists(obj_file):
        print(f"Running {testbench_name}...")
        subprocess.run(["vvp", obj_file, "-fst"])

        # Move VCD files if they exist
        for file in os.listdir('.'):
            if file.endswith('.vcd') or file.endswith('.fst') or file.endswith('.lxt'):
                target_path = os.path.join(output_folder, file)
                if os.path.exists(target_path):
                    os.remove(target_path)
                os.rename(file, target_path)

        print(f"Testbench {testbench_name} completed successfully.")
    else:
        print(f"Compilation error with {testbench_name}.")
        sys.exit(2)

# Main
def main():
    if len(sys.argv) < 2:
        print("Usage: sim.py <testbench_name>")
        sys.exit(1)

    testbench_name = sys.argv[1]
    testbenches = find_testbenches()

    print(f"{len(testbenches)} Testbenches found: {', '.join(testbenches.keys())}")

    if testbench_name not in testbenches:
        print(f"Testbench {testbench_name} not found.")
        sys.exit(1)
    else:
        print(f"Testbench {testbench_name} found.")

    ensure_directories()

    sources = collect_source_files()

    compile_and_run(testbench_name, testbenches[testbench_name], sources)

if __name__ == "__main__":
    main()
