import tkinter as tk
from tkinter import filedialog, messagebox
import requests
import webbrowser
import threading
import time
import sys

# --- Configuration ---
# The port is now passed as a command-line argument
PORT = sys.argv[1] if len(sys.argv) > 1 else "5000"
BACKEND_URL = f"http://localhost:{PORT}"

# --- Core Functions ---

def is_server_alive():
    """Checks if the backend server is responsive."""
    try:
        response = requests.get(f"{BACKEND_URL}/ping", timeout=2)
        return response.status_code == 200
    except requests.exceptions.RequestException:
        return False

def select_and_share_folder():
    """Opens a native folder picker and sends the selected path to the backend."""
    folder_path = filedialog.askdirectory(
        mustexist=True, title="Select a Folder to Share"
    )
    if not folder_path:
        return

    try:
        response = requests.post(
            f"{BACKEND_URL}/pick-folder",
            json={"path": folder_path},
            headers={"Accept": "application/json"},
            timeout=10,
        )
        response.raise_for_status()
        if response.json().get("success"):
            webbrowser.open(f"{BACKEND_URL}/files?path=")
            root.destroy()  # Close GUI, but server will keep running
        else:
            error_msg = response.json().get("error", "Unknown error.")
            messagebox.showerror("Sharing Failed", f"Server error: {error_msg}")
    except requests.exceptions.RequestException:
        messagebox.showerror("Connection Error", f"Could not connect to the backend at {BACKEND_URL}.")

def stop_server():
    """Sends a shutdown request to the backend server."""
    if not messagebox.askokcancel("Confirm", "Are you sure you want to stop the server?"):
        return

    try:
        requests.post(f"{BACKEND_URL}/shutdown", timeout=5)
        messagebox.showinfo("Server Stopped", "The backend server has been shut down.")
        root.destroy()
    except requests.exceptions.RequestException:
        messagebox.showwarning("Shutdown Failed", "Could not send shutdown signal.")
        root.destroy()

def update_server_status():
    """Periodically checks server status and updates the GUI."""
    retries = 0
    while retries < 5: # Try for 5 seconds
        if is_server_alive():
            status_label.config(text="Server Status: Online", fg="#28a745")
            share_button.config(state=tk.NORMAL)
            return
        time.sleep(1)
        retries += 1
    status_label.config(text="Server Status: Offline", fg="#dc3545")
    share_button.config(state=tk.DISABLED)

# --- GUI Setup ---
root = tk.Tk()
root.title("File Sharer Control")
root.attributes('-fullscreen', True) # Make window full screen
root.resizable(False, False)
root.tk_setPalette(background="#2e2e2e", foreground="#ffffff")

main_frame = tk.Frame(root, padx=30, pady=20)
main_frame.pack(expand=True, fill=tk.BOTH)

title_label = tk.Label(main_frame, text="File Sharer", font=("Helvetica", 22, "bold"))
title_label.pack(pady=(0, 10))

status_label = tk.Label(main_frame, text="Server Status: Checking...", font=("Helvetica", 12), fg="#ffc107")
status_label.pack(pady=(0, 20))

button_frame = tk.Frame(main_frame)
button_frame.pack()

share_button = tk.Button(
    button_frame, text="Share Folder", font=("Helvetica", 14), command=select_and_share_folder,
    width=15, height=2, bg="#007bff", fg="white", relief=tk.FLAT, state=tk.DISABLED
)
share_button.pack(side=tk.LEFT, padx=(0, 15))

stop_button = tk.Button(
    button_frame, text="Stop Server", font=("Helvetica", 14), command=stop_server,
    width=15, height=2, bg="#dc3545", fg="white", relief=tk.FLAT
)
stop_button.pack(side=tk.LEFT)

if __name__ == "__main__":
    status_thread = threading.Thread(target=update_server_status, daemon=True)
    status_thread.start()
    root.mainloop()