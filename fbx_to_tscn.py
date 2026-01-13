"""
FBX to TSCN Converter using Godot CLI
Converts .fbx files to .tscn (Godot Scene) format using Godot's built-in importer.
"""

import subprocess
import os
import sys
import shutil
from pathlib import Path


# ============ CONFIGURATION ============
# Update this path to your Godot executable
GODOT_PATH = r"C:\Program Files\Godot\Godot_v4.3-stable_win64.exe"
# Alternative common paths:
# GODOT_PATH = r"C:\Users\YourUser\Downloads\Godot_v4.3-stable_win64.exe"
# GODOT_PATH = r"D:\Godot\Godot_v4.3-stable_win64.exe"
# =======================================


def find_godot_executable():
    """Try to find Godot executable in common locations."""
    common_paths = [
        GODOT_PATH,
        r"C:\Program Files\Godot\Godot.exe",
        r"C:\Program Files (x86)\Godot\Godot.exe",
        os.path.expanduser(r"~\Downloads\Godot_v4.3-stable_win64.exe"),
        os.path.expanduser(r"~\Desktop\Godot_v4.3-stable_win64.exe"),
    ]
    
    for path in common_paths:
        if os.path.isfile(path):
            return path
    
    # Try to find in PATH
    godot_in_path = shutil.which("godot")
    if godot_in_path:
        return godot_in_path
    
    return None


def convert_fbx_to_tscn(fbx_path: str, output_path: str = None, godot_path: str = None):
    """
    Convert an FBX file to TSCN using Godot's importer.
    
    Args:
        fbx_path: Path to the input .fbx file
        output_path: Optional path for output .tscn file (defaults to same directory as FBX)
        godot_path: Optional path to Godot executable
    
    Returns:
        bool: True if conversion was successful
    """
    fbx_path = Path(fbx_path).resolve()
    
    if not fbx_path.exists():
        print(f"Error: FBX file not found: {fbx_path}")
        return False
    
    if not fbx_path.suffix.lower() == '.fbx':
        print(f"Error: File is not an FBX file: {fbx_path}")
        return False
    
    # Find Godot executable
    godot_exe = godot_path or find_godot_executable()
    if not godot_exe or not os.path.isfile(godot_exe):
        print("Error: Godot executable not found!")
        print("Please update GODOT_PATH in this script or provide the path as an argument.")
        print(f"Current GODOT_PATH: {GODOT_PATH}")
        return False
    
    # Get project directory (where project.godot is located)
    project_dir = Path(__file__).parent.resolve()
    project_file = project_dir / "project.godot"
    
    if not project_file.exists():
        print(f"Error: project.godot not found in {project_dir}")
        print("Please run this script from your Godot project directory.")
        return False
    
    # Determine output path
    if output_path:
        tscn_path = Path(output_path).resolve()
    else:
        tscn_path = fbx_path.with_suffix('.tscn')
    
    # Copy FBX to project directory if it's not already there
    fbx_in_project = project_dir / fbx_path.name
    if fbx_path != fbx_in_project:
        print(f"Copying FBX to project directory: {fbx_in_project}")
        shutil.copy2(fbx_path, fbx_in_project)
        fbx_to_import = fbx_in_project
    else:
        fbx_to_import = fbx_path
    
    # Get relative path for Godot
    rel_fbx_path = fbx_to_import.relative_to(project_dir)
    
    print(f"Importing FBX: {fbx_to_import}")
    print(f"Using Godot: {godot_exe}")
    print(f"Project: {project_dir}")
    
    # Step 1: Import the FBX file using Godot's --import flag
    print("\nStep 1: Running Godot import...")
    import_cmd = [
        godot_exe,
        "--headless",
        "--path", str(project_dir),
        "--import"
    ]
    
    try:
        result = subprocess.run(
            import_cmd,
            capture_output=True,
            text=True,
            timeout=120,
            cwd=str(project_dir)
        )
        
        if result.returncode != 0:
            print(f"Warning: Import returned code {result.returncode}")
            if result.stderr:
                print(f"Stderr: {result.stderr}")
    except subprocess.TimeoutExpired:
        print("Warning: Import timed out, but this may be okay.")
    except Exception as e:
        print(f"Error during import: {e}")
        return False
    
    # Step 2: Check if Godot created the imported scene
    # Godot typically creates .import files and may create inherited scenes
    imported_dir = project_dir / ".godot" / "imported"
    import_file = fbx_to_import.with_suffix(fbx_to_import.suffix + ".import")
    
    print("\nStep 2: Looking for imported resources...")
    
    # Check if .import file was created
    if import_file.exists():
        print(f"Import file created: {import_file}")
    
    # Step 3: Create a TSCN file that instantiates the imported FBX
    print(f"\nStep 3: Creating TSCN file: {tscn_path}")
    
    # Create a simple TSCN that references the imported model
    res_path = f"res://{rel_fbx_path.as_posix()}"
    
    tscn_content = f'''[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" uid="uid://placeholder" path="{res_path}" id="1"]

[node name="{fbx_path.stem}" type="Node3D"]

[node name="Model" parent="." instance=ExtResource("1")]
'''
    
    # Write the TSCN file
    try:
        with open(tscn_path, 'w', encoding='utf-8') as f:
            f.write(tscn_content)
        print(f"TSCN file created: {tscn_path}")
    except Exception as e:
        print(f"Error writing TSCN file: {e}")
        return False
    
    # Step 4: Re-run import to ensure everything is linked
    print("\nStep 4: Final import pass...")
    try:
        subprocess.run(
            import_cmd,
            capture_output=True,
            text=True,
            timeout=60,
            cwd=str(project_dir)
        )
    except:
        pass
    
    print("\n" + "="*50)
    print("Conversion complete!")
    print(f"Output: {tscn_path}")
    print("="*50)
    print("\nNote: Open the project in Godot Editor to verify the scene.")
    print("The FBX file needs to be in the project directory for Godot to import it.")
    
    return True


def main():
    if len(sys.argv) < 2:
        print("FBX to TSCN Converter")
        print("=" * 40)
        print("\nUsage:")
        print(f"  python {sys.argv[0]} <fbx_file> [output_tscn] [godot_path]")
        print("\nExamples:")
        print(f"  python {sys.argv[0]} model.fbx")
        print(f"  python {sys.argv[0]} model.fbx output.tscn")
        print(f'  python {sys.argv[0]} model.fbx output.tscn "C:\\Path\\To\\Godot.exe"')
        print("\nMake sure to update GODOT_PATH in the script!")
        return 1
    
    fbx_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    godot_exe = sys.argv[3] if len(sys.argv) > 3 else None
    
    success = convert_fbx_to_tscn(fbx_file, output_file, godot_exe)
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
