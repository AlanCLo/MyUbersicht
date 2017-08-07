# Dashboard for my Trello
# ====
# Pull data from Trello to visualise on my desktop.
#
# Dependencies
# * Trello API setup
# * jq installed
#
#
# You need to save your Trello API settings in
#   ~/TrelloAPI.env.sh
# with the following contents
#   export TRELLO_APP_KEY=...
#   export TRELLO_TOKEN=...
#   export TRELLO_BOARD_ID=...
#	export UBER_RECORD_SCRIPT=(full path of script including filename to execute)
#	export UBER_STATS_DB_PATH=(full path of store including filename as json)
#	export UBER_STATS_LISTS='["...", "...", "..."]'
#	export UBER_STATS_DONE=... (Needs to be an item in UBER_STATS_LISTS)



# ----
# Variables
# ----

refreshFrequency: 3600000 # Refresh every hour
trelloDoneListId: "569ed04150080cd5968c4d98" # Id of a done list which don't be processed
waitintListId: "5979792053e9f8c3142f4912"    # Id of the waiting list to highlight


# ----
# Constants
# ----

MSEC_IN_DAY: 24 * 60 * 60 * 1000
DAY_NAMES: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
OFFDAY_INDICIES:[0,6] # Sat and Sun are off days. Colour them differently

# Fetch all the cards from a board, then convert them into an an array of objects with {Name, Due, ID}
command: """
$(cat ~/TrelloAPI.env.sh)
curl --silent "https://api.trello.com/1/boards/${TRELLO_BOARD_ID}/cards?key=${TRELLO_APP_KEY}&token=${TRELLO_TOKEN}" > /tmp/Ubersicht.Trello.widget.data
/usr/local/bin/node ${UBER_RECORD_SCRIPT}
cat /tmp/Ubersicht.Trello.widget.data | /usr/local/bin/jq '[.[] | {name:.name, due:.due, idList:.idList}] | sort_by(.due)'
"""


style: """
	color: rgba(#fff, 0.9)
	font-family Helvetica Neue

	.layout
		width: 100%

	.container
		margin 20px 20px 15px
		padding 10px
		border-radius 5px
		float: left
		max-width: 400px
	
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
		background: rgba(#aaf, 0.2)
			
	.midline
		padding-left: 0px
		padding-right: 0px
		width: 1px
		background: rgba(#0af, 0.8)
		
	.content
		font-size: 16px
		font-weight: bold

	.today
		background: rgba(#afa, 0.2)


	#thisMonth
		background: rgba(#030, 0.2)


	#nextMonth
		background: rgba(#003, 0.2)


	#beyond
		background: rgba(#000, 0.5)


	#waiting
		background: rgba(#522, 0.5)
		float: left
		
"""

render: -> """
	<div class="layout">
			<div class="container" id="thisMonth">
				<div class="title">This Month</div>
				<table></table>
			</div>
			<div class="container" id="nextMonth">
				<div class="title">Next Month</div>
				<table></table>
			</div>
			<div class="container" id="beyond">
				<div class="title">Beyond</div>
				<table></table>
			</div>
			<div class="container" id="waiting">
				<div class="title">Waiting or Blocked</div>
				<table></table>
			</div>
	</div>
"""


# ----
# Update
# ----

update: (output, domEl) ->
	cards = JSON.parse(output)

	drawTable = (uber, cards, domEl, containerId, isThisMonth) ->
		$dailyList = $(domEl).find(containerId).find("table")
		$dailyList.empty()

		now = new Date()
		if !isThisMonth
			now.setMonth(now.getMonth() + 1)
		y = now.getFullYear()
		m = now.getMonth()
		today = now.getDate()

		if isThisMonth
			i = today
		else
			i = 1
		w = new Date(y, m, i).getDay()
		lastDate = new Date(y, m + 1, 0).getDate()

		while i <= lastDate
			w %= 7
			isToday = (i is today) and isThisMonth
			todayClass = "today"
			if !isToday
				todayClass = ""
			isOffday = (uber.OFFDAY_INDICIES.indexOf(w) isnt -1)
			offDayClass = "off"
			if !isOffday
				offDayClass = ""
		
			dayText = uber.DAY_NAMES[w]

			num = 0
			for cardData in cards
				if cardData.idList == uber.trelloDoneListId or cardData.due is null
					continue
				cardDate = new Date(cardData.due)
				if cardDate.getFullYear() == y and cardDate.getMonth() == m and cardDate.getDate() == i
					html = "<tr>"
					if num == 0
						html += """<td class="day #{offDayClass}">#{dayText} #{i}</td>"""
					else
						html += """<td class="day #{offDayClass}"></td>"""

					html += """<td class="midline"></td>"""
					html += """<td class="content #{todayClass}">#{cardData.name}</td>"""

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

	drawBeyond = (uber, cards, domEl, containerId) ->
		$beyondTable = $(domEl).find(containerId).find("table")
		$beyondTable.empty()

		now = new Date()
		# Beyond is any card not this month, or next month (i.e. +2 months)
		# Date to compare is the 1st day of the month after the next
		next = new Date(now.getFullYear(), now.getMonth() + 2, 1)

		daysDiff = (d1, d2) -> Math.round((d2 - d1)/uber.MSEC_IN_DAY)

		hasRecords = false
		for cardData in cards
			if cardData.idList == uber.trelloDoneListId or cardData.due is null
				continue
			cardDate = new Date(cardData.due)
			if cardDate > next
				html = "<tr>"
				html += "<td>#{cardDate.toISOString().substring(0,10)}</td>"
				diff = daysDiff(now, cardDate)
				html += "<td>(#{diff} DAYS)</td>"
				html += """<td class="content">#{cardData.name}</td></tr>"""
				html += "</tr>"
				$beyondTable.append(html)
				hasRecords = true

		if hasRecords == false
			$beyondTable.append("""<tr><td class="content">(None)</td></tr>""")


	drawWaiting = (uber, cards, domEl, containerId) ->
		$waitingTable = $(domEl).find(containerId).find("table")
		$waitingTable.empty()

		for cardData in cards
			if cardData.idList == uber.waitintListId
				html = "<tr>"
				html +=  """<td>#{cardData.name}</td>"""
				if cardData.due is null
					html += "<td></td>"
				else
					cardDate = new Date(cardData.due)
					html += """<td>#{cardDate.toISOString().substring(0,10)}</td>"""
				html += "</tr>"
				$waitingTable.append(html)


	drawTable(@, cards, domEl, "#thisMonth", true)
	drawTable(@, cards, domEl, "#nextMonth", false)
	drawBeyond(@, cards, domEl, "#beyond")
	drawWaiting(@, cards, domEl, "#waiting")




