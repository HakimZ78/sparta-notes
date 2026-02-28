1. IF YOU WANT - Finish the DB manual deployment if you haven't already.
- Download mongodb 7.x
- Change configuration: bindIP = 0.0.0.0 (in /etc/mongod.conf).
- Create env var in app instance (export DB_HOST=mongodb://10.0.3.4:27017/posts)
- Remember the command above has a placeholder, replace it with your db ip.
- Run the app again (do node seeds/seed.js before starting it with pm2).
2. OPTIONAL - Redo the db deployment from scratch, documenting as you go.
- Screenshots recommended
- Make sure to explain commands used
- Links also helpful
- Use markdown
3. Write a script to deploy mongodb
- V1 should install mongodb, still need to do configuration manually
- V2 should automate the configuration change
    - Hint: Use the "sed" command to achieve this
4. Write a V2 script to deploy the app with the following improvements:
- Automate the nginx reverse proxy configuration change
  - Use "sed"
- Automate the setting of the DB_HOST environment variable and DB seeding 
5. SUPER OPTIONAL EXTRAS
- Work out how to make the env var (DB_HOST) persistent (exist between sessions)
- Research Reverse Proxy's
  - What are Proxy servers?
  - What are Reverse Proxy servers?
  - What are the benefits?
  - Write up a guide on how to set up a basic one

Tomorrow we will review our scripts to get everyone on the same page and then we will look at making custom AMIs!