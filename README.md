hubot-trello
============

manage your trello board from hubot


## Installation

Add **hubot-trello** to your `package.json` file:

```json
"dependencies": {
  "hubot": ">= 2.5.1",
  "hubot-scripts": ">= 2.4.2",
  "hubot-trello": "*"
}
```

OR run `npm install --save hubot-trello`

Add **hubot-trello** to your `external-scripts.json`:

```json
["hubot-trello"]
```

Run `npm install`


## Configuration

Setup the following as environment variables before you run hubot.

```
HUBOT_TRELLO_KEY    - Trello application key
HUBOT_TRELLO_TOKEN  - Trello API token
HUBOT_TRELLO_BOARD  - The ID of the Trello board you will be working with
```

- To get your key, go to: `https://trello.com/1/appKey/generate`
- To get your token, go to: `https://trello.com/1/authorize?key=<<your key>>&name=Hubot+Trello&expiration=never&response_type=token&scope=read,write`
- Figure out what board you want to use, grab it's id from the url `https://trello.com/b/<<board id>>/<<board name>>`


## Sample Interaction

```
user1> hubot trello new "to do" my simple task
Hubot> Sure thing boss. I'll create that card for you.
Hubot> OK, I created that card for you. You can see it here: http://trello.com/c/<shortLink>
user1> hubot trello move <shortLink> "doing"
Hubot> Yep, ok, I moved that card to doing.
user1> hubot trello list "to do"
Hubot> user1: Looking up the cards for to do, one sec...
Hubot> user1: Here are all the cards in To Do
Hubot> * [<shortLink>] <card_name> - <card_url>
Hubot> * [<shortLink>] <card_name> - <card_url>
Hubot> * [<shortLink>] <card_name> - <card_url>
user1> hubot trello list lists
Hubot> user1: Here are all the lists on your board.
Hubot> * to do
Hubot> * doing
Hubot> * done
```

And you can use a little help command.

```
user1> trello help
```

