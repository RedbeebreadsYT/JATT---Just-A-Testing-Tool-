🚀 How to Run JATT
Method 1: The Quick Install (Recommended)
This command downloads JATT and sets it up so you can run it just by typing jatt from anywhere. Copy and paste this into your terminal:

	sudo wget https://raw.githubusercontent.com/RedbeebreadsYT/JATT---Just-A-Testing-Tool-/main/JATT.sh -O /usr/local/bin/jatt && sudo chmod +x /usr/local/bin/jatt

Once finished, simply type sudo jatt to start the tool!

Method 2: Manual Run
If you have already downloaded the JATT.sh file manually, follow these steps:

Give Permission: ```bash
chmod +x JATT.sh

Run with Root Privileges:

Bash
	sudo ./JATT.sh
Why the extra steps?
Permissions (chmod +x): Linux requires you to "unlock" a script before it can be executed as a program.

Root (sudo): JATT needs to talk directly to your screen hardware (framebuffer) to handle rotation and color tests, which requires administrator access.

