#!/usr/bin/env coffee

util = require 'util'
request = require 'request-promise-native'
ynab = require 'ynab'
moment = require 'moment'
md5 = require 'md5'

simplefin_get_transactions = () ->


do () -> try
  required_envs = [
    'SIMPLEFIN_ACCESS_USER'
    'SIMPLEFIN_ACCESS_PASSWORD'
    'SIMPLEFIN_ACCESS_URL'
    'SIMPLEFIN_ACCOUNT_NAME'
    'YNAB_API_TOKEN'
    'YNAB_BUDGET_NAME'
  ]
  missing_envs = required_envs.filter (env) -> not process.env[env]?
  if missing_envs.length > 0
    throw new Error "Missing envs: #{missing_envs.join ', '}"

  try
    data = await request.get {
      auth: {
        user: process.env.SIMPLEFIN_ACCESS_USER
        pass: process.env.SIMPLEFIN_ACCESS_PASSWORD
      }
      url: process.env.SIMPLEFIN_ACCESS_URL + '/accounts'
      json: true
    }
  catch err
    throw new Error "Got status code: #{err.statusCode} from Simplefin, check your credentials!" if err.name == 'StatusCodeError'
    throw err

  simplefin_account = data.accounts.find (a) -> a.name == process.env.SIMPLEFIN_ACCOUNT_NAME
  throw new Error "Account: #{process.env.SIMPLEFIN_ACCOUNT_NAME} not found, set SIMPLEFIN_ACCOUNT_NAME env to one of: [#{data.accounts.map((a) -> a.name).join ', '}]" unless simplefin_account?

  transactions = simplefin_account.transactions

  console.log util.inspect transactions, {depth: 5}

  ynab_api = new ynab.API process.env.YNAB_API_TOKEN
  budgets = await ynab_api.budgets.getBudgets()
  budget = budgets.data.budgets.find (b) -> b.name == process.env.YNAB_BUDGET_NAME
  throw new Error "Budget: #{process.env.YNAB_BUDGET_NAME} not found, set YNAB_BUDGET_NAME env to one of: [#{budgets.data.budgets.map((b) -> b.name).join ', '}]" unless budget?

  accounts = await ynab_api.accounts.getAccounts budget.id
  account = accounts.data.accounts.find (a) -> a.name == process.env.YNAB_ACCOUNT_NAME
  throw new Error "Account: #{process.env.YNAB_ACCOUNT_NAME} not found, set YNAB_ACCOUNT_NAME env to one of: [#{accounts.data.accounts.map((a) -> a.name).join ', '}]" unless account?

  # console.log util.inspect account

  ynab_trx = transactions.map (t) ->
    {
      account_id: account.id
      date: moment.unix(t.posted).format 'YYYY-MM-DD'
      amount: t.amount * 1000 # convert to milliunits
      payee_name: if payee = t.description.match(/Payee\:\s+(.+)$/) then payee[1] else t.description
      memo: t.description
      import_id: md5 t.id
      cleared: "cleared"
    }
  total = duplicate = 0
  for transaction from ynab_trx
    try
      await ynab_api.transactions.createTransactions budget.id, {transaction}
      total += 1
    catch err
      if err.error.name == 'conflict' and err.error.detail.includes 'same import_id'
        duplicate += 1
      else
        console.error err
        console.error util.inspect transaction
  console.log "Imported #{total}, Duplicate #{duplicate}"
catch err
  console.error err
  process.exit 1
