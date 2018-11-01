# Simplefin to YNAB syncer

This is a simple script that connects a given [Simplefin](https://www.simplefin.org) to [YNAB (You Need a Budget)](https://www.youneedabudget.com).  This can be useful in the case where YNAB does not support syncing with your Financial institution but Simplefin does.  

You can run this as a docker container, or just download this repository, install the dependencies and run the script directly.  You must provide the proper environment variables (see below) in any case.  

## Requirements

* A Simplefin Bridge Account hooked up to your Bank account you want to sync transactions _from_.
* A YNAB API token and the Budget/Account you want to sync transactions _to_.

### Simplefin

1. Signup for a Simplefin account.  You may need to be added to the waitlist first.
2. Login to your Simplefin bridge and connect your bank.
3. Use the 'Connect an app' function.  This will give you a "SETUP token".  
4. Base64 decode the token to get a Setup URL and send a POST to the url:
```
curl -X POST `echo '$SIMPLEFIN_SETUP_TOKEN' | base64 -D
```
5. The above should spit out a url in this format: `https://<very long hex username>:<very long hex password>@bridge.simplefin.org/simplefin` or similar.  The username will be your SIMPLEFIN_ACCESS_USER env variable, the password your SIMPLEFIN_ACCESS_PASSWORD and your SIMPLEFIN_ACCESS_URL will mostly likely be https://bridge.simplefin.org/simplefin, or the above url without the user:password@ part.   
6. Run `curl <above URL>/accounts`.  This will give you a JSON file that lists your connected accounts.   Take note of the "name" parameter of the account you want, this will be your SIMPLEFIN_ACCOUNT_NAME environment variable.  
7. You have all your SIMPLEFIN variables!

### YNAB

1. I assume you already have a YNAB account, a Budget setup and an unlinked financial institution there you want to put transctions into.  Your budget name is the YNAB_BUDGET_NAME variables, and the account name (e.g., 'Checking') is your YNAB_ACCOUNT_NAME.  THESE MUST MATCH EXACTLY!
2. In the YNAB web app, click your email in the lower left corner and select 'My Account'.  From there, click 'Developer Settings'.  Create a 'Personal Access Token' from there.  This is your 'YNAB_API_TOKEN'

## All ENV variables

* TRANSACTION_AGE_DAYS: Number of days to sync, note the YNAB api will prevent duplicates.
* SIMPLEFIN_ACCESS_USER: Username component of the URL fetched with the decoded Simplefin SETUP token. NOT your Simplefin user/email!
* SIMPLEFIN_ACCESS_PASSWORD: Password component of the URL fetched with the decoded Simplefin SETUP token.
* SIMPLEFIN_ACCESS_URL: The URL left over when you take out the user/password.  Most likely it is "https://bridge.simplefin.org/simplefin".
* YNAB_API_TOKEN: YNAB "Personal Access Token".
* YNAB_BUDGET_NAME: The YNAB Budget name to sync to
* YNAB_ACCOUNT_NAME: Name of the account under the above budget you want to sync transactions into.

## Install

### Just run the script

Roughly,
1. `git clone` locally
2. `npm install` to get the JS deps.  You probably will need `npm install -g coffeescript` too.
3. Set your env variables
4. `./sync.coffee`

### Docker

docker-compose provided.  You can build your own or pull from docker hub.  

## Caveats

* This works with my Bank's checking account.  I have not tested this on other accounts. I'm unsure how much Simplefin normalizes bank transaction data, so your mileage may vary.  
* I'm opensourcing this so that others don't have to replicate what I did to get my bank to sync (and YNAB refuses to sync with my bank after more than a year of asking!).  I am not your personal developer and owe you nothing.  If this works for you, great!  There is no warranty or guarantees it won't destroy the world.  
* If you don't know what an environment variable is, this is not for you!

## Contributing

I'm happy to merge PRs that don't break my process.

## Wishlist

* This just runs a one-off, I'd love for a Docker cron setup to be added so I can set this up and forget it.  Maybe someday soon.
