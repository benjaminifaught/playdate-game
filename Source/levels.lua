local levels = {
	{
		levelNumber = 1,
		timeLimit = 30,
		playerStartX = 32,
		playerStartY = 188,
		itemX = 200,
		itemY = 188,
		boxX = 368,
		boxY = 188,
	},
	{
		levelNumber = 2,
		timeLimit = 25,
		playerStartX = 32,
		playerStartY = 188,
		itemX = 184,
		itemY = 188,
		boxX = 368,
		boxY = 188,
	},
	{
		levelNumber = 3,
		timeLimit = 20,
		playerStartX = 32,
		playerStartY = 188,
		itemX = 216,
		itemY = 188,
		boxX = 368,
		boxY = 188,
	},
}

-- Playdate's import executes modules without returning their values.
playdate._fulfillmentFrenzyLevels = levels
