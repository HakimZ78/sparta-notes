1. OPTIONAL. Redo the manual deployment on a fresh EC2 instance (and document if you feel like it will help.:
- Copy code from local machine
- Unzip .zip file
- Update and Upgrade
- Install nginx
- Install nodejs 20.x
- Install app
- Start app
2. Write a bash script to deploy the Sparta App. Bare in mind you will need to:
- Use Git and GitHub to get the app code (git clone)
- Bonus: Can you get the app to run in the background rather than the foreground.
- Try to use pm2 for the above!
3. BONUS OPTIONAL: Implement a reverse proxy for nginx so that the ip address (with no :3000) shows the sparta app when it is run.
- You will need to edit the nginx config to do this
- Here is a guide: https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-20-04
- Do manually before you try to add it to your script.