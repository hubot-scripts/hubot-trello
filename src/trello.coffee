# Description:
#   Manage your Trello Board from Hubot!
#
# Dependencies:
#   "node-trello": "latest"
#
# Configuration:
#   HUBOT_TRELLO_KEY - Trello application key
#   HUBOT_TRELLO_TOKEN - Trello API token
#   HUBOT_TRELLO_BOARD - The ID of the Trello board you will be working with
#
# Commands:
#   hubot trello new "<list>" <name> - Create a new Trello card in the list
#   hubot trello list "<list>" - Show cards on list
#   hubot trello move <shortLink> "<list>" - Move a card to a different list
#   hubot trello add member <shortlink> "<first name of member>"
#   hubot trello add comment <shortlink> "<comment>"
#   hubot trello description <shortlink> "<discription>"
#   hubot trello search "<criteria>"
#   hubot trello get <name>'s cards
#   hubot trello create list "<name>" (optional: top' or bottom)
#
# Author:
#   jared barboza <jared.m.barboza@gmail.com>

board = {}
lists = {}
members = {}

Trello = require 'node-trello'

trello = new Trello process.env.HUBOT_TRELLO_KEY, process.env.HUBOT_TRELLO_TOKEN

# verify that all the environment vars are available
ensureConfig = (out) ->
  out "Error: Trello app key is not specified" if not process.env.HUBOT_TRELLO_KEY
  out "Error: Trello token is not specified" if not process.env.HUBOT_TRELLO_TOKEN
  out "Error: Trello board ID is not specified" if not process.env.HUBOT_TRELLO_BOARD
  return false unless (process.env.HUBOT_TRELLO_KEY and process.env.HUBOT_TRELLO_TOKEN and process.env.HUBOT_TRELLO_BOARD)
  true

##############################
# API Methods
##############################

createCard = (msg, list_name, cardName) ->
  msg.reply "Sure thing boss. I'll create that card for you."
  ensureConfig msg.send
  id = lists[list_name.toLowerCase()].id
  trello.post "/1/cards", {name: cardName, idList: id}, (err, data) ->
    msg.reply "There was an error creating the card" if err
    msg.reply "OK, I created that card for you. You can see it here: #{data.url}" unless err

showCards = (msg, list_name) ->
  msg.reply "Looking up the cards for #{list_name}, one sec."
  ensureConfig msg.send
  id = lists[list_name.toLowerCase()].id
  msg.send "I couldn't find a list named: #{list_name}." unless id
  if id
    trello.get "/1/lists/#{id}", {cards: "open"}, (err, data) ->
      msg.reply "There was an error showing the list." if err
      msg.reply "Here are all the cards in #{data.name}:" unless err and data.cards.length == 0
      msg.send "* [#{card.shortLink}] #{card.name} - #{card.shortUrl}" for card in data.cards unless err and data.cards.length == 0
      msg.reply "No cards are currently in the #{data.name} list." if data.cards.length == 0 and !err

getMemberId = (msg, member_name) ->
  if (members[member_name.toLowerCase()]?)
     id = members[member_name.toLowerCase()].id
  msg.send "Unable to find person named: #{member_name}" unless id?
  if id?
     msg.send " * #{id}"

addMember = (msg, card_id, member_name) ->
  if (members[member_name.toLowerCase()]?)
     id = members[member_name.toLowerCase()].id
  msg.send "Unable to find person named: #{member_name}" unless id?
  if id?
     trello.put "/1/cards/#{card_id}/idMembers", {value: id}, (err, data) ->
       msg.reply "Sorry captain, I couldn't add that member" if err
       msg.reply "Success! #{member_name} was added" unless err

getMemberCards = (msg, member_name) ->
  if (members[member_name.toLowerCase()]?)
     id = members[member_name.toLowerCase()].username
  msg.send "Unable to find person named: #{user_name}" unless id?
  if id?
    trello.get "/1/search", {query: "@"+id, idBoards: board.id, modelTypes: "cards", card_fields: "name,shortLink,url"}, (err, data) ->
      msg.reply "So sorry, I got an error and cannot give you that information" if err
      msg.reply "I got the following cards for you" unless err
      msg.send board.id
      msg.send id
      for cards in data.cards
        msg.send " * #{cards.name} | #{cards.url}"
        
search = (msg, search) ->
  if (search?)
    msg.reply "I'm searching for results now"
    trello.get "/1/search", {query: search, idBoards: board.id, modelTypes:"cards", card_fields: "name,shortLink,url"}, (err, data) ->
      msg.reply "Sorry, I was unable to search at this time. Please try again later." if err
      msg.reply "The following cards match your criteria" unless err
      for cards in data.cards
         msg.send " * #{cards.name} | #{cards.url}"
         
createList = (msg, list_name, position = "top") ->
  msg.reply "I'll get right on that!"
  if position is "top" or position is "bottom" or position > 0
    trello.post "/1/lists", {name: list_name, idBoard: board.id, pos:position}, (err, data) ->
      msg.reply "I'm sorry I was unable to add that list. Please try again later." if err
      msg.reply "That list has been created and be viewed here: #{board.url}" unless err
  else msg.reply "I'm sorry I can't create a list in that position"


moveCard = (msg, card_id, list_name) ->
  ensureConfig msg.send
  id = lists[list_name.toLowerCase()].id
  msg.reply "I couldn't find a list named: #{list_name}." unless id
  if id
    trello.put "/1/cards/#{card_id}/idList", {value: id}, (err, data) ->
      msg.reply "Sorry boss, I couldn't move that card after all." if err
      msg.reply "Yep, ok, I moved that card to #{list_name}." unless err

addDescription = (msg, card_id, desc) ->
  ensureConfig msg.send
  trello.put "/1/cards/#{card_id}/desc", {value: desc}, (err, data) ->
    msg.reply "Sorry boss, I couldn't update that card after all." if err
    msg.reply "Yep, ok, I updated that card for you." unless err

addComment = (msg,card_id, comment, usr) ->
  ensureConfig msg.send
  trello.post "/1/cards/#{card_id}/actions/comments",{text: usr+" commented via Slack:"+comment}, (err, data) ->
    msg.reply "Sorry, I was unable to do that." if err
    msg.reply "Gladly! That comment has been added" unless err

module.exports = (robot) ->
  # fetch our board data when the script is loaded
  ensureConfig console.log
  trello.get "/1/boards/#{process.env.HUBOT_TRELLO_BOARD}", (err, data) ->
    board = data
    trello.get "/1/boards/#{process.env.HUBOT_TRELLO_BOARD}/lists", (err, data) ->
      for list in data
        lists[list.name.toLowerCase()] = list
    trello.get "/1/boards/#{process.env.HUBOT_TRELLO_BOARD}/members", (err, data) ->
      for member in data
        members[member.fullName.toLowerCase().split " ", 1] = member


  robot.respond /trello new ["“'‘](.+)["”'’]\s(.*)/i, (msg) ->
    ensureConfig msg.send
    card_name = msg.match[2]
    list_name = msg.match[1]

    if card_name.length == 0
      msg.reply "You must give the card a name"
      return

    if list_name.length == 0
      msg.reply "You must give a list name"
      return
    return unless ensureConfig()

    createCard msg, list_name, card_name

  robot.respond /trello list ["“'‘](.+)["”'’]/i, (msg) ->
    showCards msg, msg.match[1]

  robot.respond /trello move (\w+) ["“'‘](.+)["”'’]/i, (msg) ->
    moveCard msg, msg.match[1], msg.match[2]

  robot.respond /trello comment (\w+) ["“'‘]((.+|\n)+)["”'’]/i, (msg) ->
    addComment msg, msg.match[1], msg.match[2], msg.message.user.name

  robot.respond /trello description (\w+) ["“'‘]((.+|\n)+)["”'’]/i, (msg) ->
    addDescription msg, msg.match[1], msg.match[2]

  robot.respond /trello get (\w+)['’]s cards/i, (msg) ->
    getMemberCards msg, msg.match[1]
    
  robot.respond /trello search ["“'‘]((.+|\n)+)["”'’]/i, (msg) ->
     search msg, msg.match[1]

  robot.respond /trello list lists/i, (msg) ->
    msg.reply "Here are all the lists on your board."
    Object.keys(lists).forEach (key) ->
      msg.send " * #{key}"

  robot.respond /trello list members/i, (msg) ->
    msg.reply "Here are all the members of the board"
    Object.keys(members).forEach (member)->
    msg.send " * #{member}"

  robot.respond /trello list member id (\w+)/i, (msg) ->
    msg.reply "The member id for #{msg.match[1]} is: "
    getMemberId msg, msg.match[1]

  robot.respond /trello add member (\w+) (\w+)/i, (msg) ->
    addMember msg, msg.match[1], msg.match[2]
    
  robot.respond /trello create list ["“'‘]((.+|\n)+)["”'’] ?(.+)?$/i, (msg) ->
    createList msg, msg.match[1], msg.match[3]

  robot.respond /trello help/i, (msg) ->
    msg.reply "Here are all the commands for me."
    msg.send " *  trello new \"<ListName>\" <TaskName>"
    msg.send " *  trello list \"<ListName>\""
    msg.send " *  shows * [<card.shortLink>] <card.name> - <card.shortUrl>"
    msg.send " *  trello move <card.shortlink> \"<ListName>\""
    msg.send " *  trello list lists"
    msg.send " *  trello list member id <name>"
    msg.send " *  trello get <first name>'s cards"
    msg.send " *  trello add member <card.shortLink> <Name>"
    msg.send " *  trello comment <card.shortLink> <Comment>"
    msg.send " *  trello description <card.shortLink> <Description>"
    msg.send " *  trello search <criteria>"
    msg.send " *  trello create list \"<name>\" (optional:top or bottom)"
