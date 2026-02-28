1. IF NOT DONE ALREADY - Deploy Sparta app and DB together (/posts page working)
2. Make an app image and test it
- Similar process as for DB image
- Stop instance before making the image
- You will need to SSH in to run the app
- Also to connect + seed the database
- Delete initial instance when you have verified the image works
3. OPTIONAL - Redo the image deployment for your db and app from scratch, documenting as you go.
- Screenshots recommended
- Links also helpful
- Use markdown
4. Find a way to automate the app deployment further
- First, use user data (found in the "Advanced Details" section of instance creation) to get the app running without needing to log in via SSH
   - i.e. the app homepage works "out of the box"
- If you manage the above, improve your user data script to also connect and seed to your database
    - The /posts page should also work "out of the box"
- I recommend saving your user data scripts in the same way you do your normal shell scripts
- Note, User Data scripts are run as the "root" user. That may chance the commands needed compared to what we have been using
6. OPTIONAL - Look into AWS CloudWatch and monitoring
- Redo the enabling of detailed monitoring on an EC2 instance, and make a dashboard to visualise metrics
- Then set up an alarm that triggers when cpu percentage goes over 50%
- Find a way to trigger it
- Improve/remake your alarm so that sends you an email if your alarm is triggered

Please clean up before you log off. Do not have any:
- Dashboards
Or
- Running instances

By the time you log off for the day.

