# Dashboard for my Trello
# ====
# Pull data from Trello to visualise on my desktop.
#
# Dependencies
# * Trello API setup
# * jq installed


# You need to save your Trello API settings in
#   ~/TrelloAPI.env.sh
# with the following contents
#   export TRELLO_APP_KEY=...
#   export TRELLO_TOKEN=...
#   export TRELLO_BOARD_ID=...




# ----
# Variables
# ----

refreshFrequency: 3600000 # Refresh every hour

# ----
# Constants
# ----

DAY_NAMES: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
OFFDAY_INDICIES:[0,6] # Sat and Sun are off days. Colour them differently


# Fetch all the cards from a board, then convert them into an an array of objects with {Name, Due, ID}
command: """
$(cat ~/TrelloAPI.env.sh)
curl --silent "https://api.trello.com/1/boards/${TRELLO_BOARD_ID}/cards?key=${TRELLO_APP_KEY}&token=${TRELLO_TOKEN}" | \
/usr/local/bin/jq '[.[] | select(.due != null) | {name:.name, due:.due, idList:.idList}] | sort_by(.due)'
"""


style: """
	*
		margin 0
		padding 0
		color rgba(#fff, 0.9)
		font-family Helvetica Neue

	.container
		background rgba(#000, .5)
		margin 20px 20px 15px
		padding 10px
		border-radius 5px
	
	.title
		font-size: 14px
		font-weight: 500
		padding-bottom: 5px
		text-transform: uppercase	
	

	table
		border-collapse: collapse
		
	td
		padding: 4px 4px 4px 4px
		text-align: left
		font-size: 11px
	
	.day
		text-align: right
		background: rgba(#fff, 0.1)
		
	.off
		background: rgba(#fff, 0.2)
			
	.midline
		padding-left: 0px
		padding-right: 0px
		width: 1px
		background: rgba(#0bf, 0.8)
		
	.content
		font-size: 13px

	.today
		background: rgba(#afa, 0.2)
		
"""

render: -> """
	<div class="container" id="thisMonth">
		<div class="title"></div>
		<table></table>
	</div>
"""




update: (output, domEl) ->
	countdowns = JSON.parse(output)

	now = new Date().getTime()

	container = "#thisMonth"

	#drawTable(countdowns, domEl, container, now)
	#drawTable = (countdowns, domEl, container, now) ->
	$titleDiv = $(domEl).find(container).find("div.title")
	$titleDiv.append("This Month")

	$countdownList = $(domEl).find(container).find("ul")
	$countdownList.empty()



		
	$dailyList = $(domEl).find(container).find("table")
	$dailyList.empty()

	nowDate = new Date()
	y = nowDate.getFullYear()
	m = nowDate.getMonth()
	today = nowDate.getDate()
	firstWeekDay = new Date(y, m, 1).getDay()
	lastDate = new Date(y, m + 1, 0).getDate()

	i = 1
	w = firstWeekDay

	while i <= lastDate
		w %= 7
		isToday = (i is today)
		todayClass = "today"
		if !isToday
			todayClass = ""
		isOffday = (@OFFDAY_INDICIES.indexOf(w) isnt -1)
		offDayClass = "off"
		if !isOffday
			offDayClass = ""
	
		dayText = @DAY_NAMES[w]
	
		num = 0
		for countdown in countdowns
			if countdown.idList == "569ed04150080cd5968c4d98" # Done list
				continue
			cardDate = new Date(countdown.due)
			if cardDate.getFullYear() == y and cardDate.getMonth() == m and cardDate.getDate() == i
				html = "<tr>"
				if num == 0
					html += """<td class="day #{offDayClass}">#{dayText} #{i}</td>"""
				else
					html += """<td class="day #{offDayClass}"></td>"""

				html += """<td class="midline"></td>"""
				html += """<td class="content #{todayClass}">#{countdown.name}</td>"""

				html += "</tr>"
				$dailyList.append(html)
				num++
	
		if num == 0
			$dailyList.append("""
				<tr>
					<td class="day #{offDayClass}">#{dayText} #{i}</td>
					<td class="midline"></td>
					<td class="content #{todayClass}"></td>
				</tr>
			""")
		i++
		w++
