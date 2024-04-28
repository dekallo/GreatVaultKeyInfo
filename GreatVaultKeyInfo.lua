-- globals
local C_MythicPlus, C_ChallengeMode, C_WeeklyRewards = C_MythicPlus, C_ChallengeMode, C_WeeklyRewards
local GetDetailedItemLevelInfo, DifficultyUtil, PVPUtil, CreateFrame, max = GetDetailedItemLevelInfo, DifficultyUtil, PVPUtil, CreateFrame, max
local WeeklyRewardsFrame, GameTooltip, Enum = WeeklyRewardsFrame, GameTooltip, Enum
local GameTooltip_SetTitle, GameTooltip_AddNormalLine, GameTooltip_AddHighlightLine, GameTooltip_AddColoredLine, GameTooltip_AddBlankLineToTooltip = GameTooltip_SetTitle, GameTooltip_AddNormalLine, GameTooltip_AddHighlightLine, GameTooltip_AddColoredLine, GameTooltip_AddBlankLineToTooltip
local WEEKLY_REWARDS_MYTHIC_TOP_RUNS, WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, WEEKLY_REWARDS_COMPLETE_MYTHIC = WEEKLY_REWARDS_MYTHIC_TOP_RUNS, WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, WEEKLY_REWARDS_COMPLETE_MYTHIC
local WEEKLY_REWARDS_HEROIC, WEEKLY_REWARDS_MYTHIC, WEEKLY_REWARDS_MAXED_REWARD, WEEKLY_REWARDS_CURRENT_REWARD, WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, WEEKLY_REWARDS_ITEM_LEVEL_HEROIC = WEEKLY_REWARDS_HEROIC, WEEKLY_REWARDS_MYTHIC, WEEKLY_REWARDS_MAXED_REWARD, WEEKLY_REWARDS_CURRENT_REWARD, WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, WEEKLY_REWARDS_ITEM_LEVEL_HEROIC
local GREEN_FONT_COLOR, GRAY_FONT_COLOR, GENERIC_FRACTION_STRING = GREEN_FONT_COLOR, GRAY_FONT_COLOR, GENERIC_FRACTION_STRING
local WeeklyRewardsUtil = WeeklyRewardsUtil

-- locals
-- this is from https://wago.tools/db2/MythicPlusSeasonRewardLevels?page=1&sort[WeeklyRewardLevel]=asc&filter[MythicPlusSeasonID]=98
local ItemLevelsBySeason = {
	-- Dragonflight Season 4
	[100] = {
		["HEROIC"] = 489,
		["MYTHIC"] = 506,
	},
}
-- fallback value
local WEEKLY_MAX_DUNGEON_THRESHOLD = 8

-- localization
local L = {}
L.reward_locked = "Reward Locked"
L.run_to_unlock = "Run %1$d more to unlock"
L.run_this_week = "%1$d run this week"
L.runs_this_week = "%1$d runs this week"
L.top_runs_this_week = "Top %d of %d Runs This Week"

-- event frame
local GreatVaultKeyInfoFrame = CreateFrame("Frame")
GreatVaultKeyInfoFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
GreatVaultKeyInfoFrame:SetScript("OnEvent", function(self, event_name, ...)
	if self[event_name] then
		return self[event_name](self, event_name, ...)
	end
end)

local GetCurrentSeasonRewardLevels = function()
	local _, _, rewardSeasonID = C_MythicPlus.GetCurrentSeasonValues()
	local currentSeasonRewardLevels = ItemLevelsBySeason[rewardSeasonID]
	if currentSeasonRewardLevels then
		return currentSeasonRewardLevels.HEROIC, currentSeasonRewardLevels.MYTHIC
	end
end

-- calculate the max reward threshold
local calcMaxRewardThreshold = WEEKLY_MAX_DUNGEON_THRESHOLD
function GreatVaultKeyInfoFrame:CHALLENGE_MODE_MAPS_UPDATE()
	calcMaxRewardThreshold = 0
	local activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Activities)
	for _, activityInfo in ipairs(activities) do
		calcMaxRewardThreshold = max(calcMaxRewardThreshold, activityInfo.threshold)
	end
	-- fallback to the default if result is empty
	if calcMaxRewardThreshold == 0 then
		calcMaxRewardThreshold = WEEKLY_MAX_DUNGEON_THRESHOLD
	end
end

-- reward progress tooltips (for unearned tiers)
local HandleInProgressMythicRewardTooltip = function(self)
	GameTooltip_SetTitle(GameTooltip, L.reward_locked)
	local runHistory = C_MythicPlus.GetRunHistory(false, true)
	local numHeroic, numMythic, numMythicPlus = C_WeeklyRewards.GetNumCompletedDungeonRuns()
	local numDungeons = numHeroic + numMythic + numMythicPlus
	GameTooltip_AddNormalLine(GameTooltip, string.format(L.run_to_unlock, self.info.threshold - numDungeons))
	if numDungeons > 0 then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		if self.info.threshold == calcMaxRewardThreshold then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(numDungeons == 1 and L.run_this_week or L.runs_this_week, numDungeons))
		else
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, self.info.threshold))
		end
	end
	if #runHistory > 0 then
		local comparison = function(entry1, entry2)
			if entry1.level == entry2.level then
				return entry1.mapChallengeModeID < entry2.mapChallengeModeID
			else
				return entry1.level > entry2.level
			end
		end
		table.sort(runHistory, comparison)
		for i = 1, #runHistory do
			if runHistory[i] then
				local runInfo = runHistory[i]
				local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID)
				local rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(runInfo.level)
				if i == #runHistory or i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel), GREEN_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel))
				end
			end
		end
	end
	local HEROIC_ITEM_LEVEL, MYTHIC_ITEM_LEVEL = GetCurrentSeasonRewardLevels()
	if numMythic > 0 then
		for i = 1, numMythic do
			if i == numMythicPlus + numMythic or i == self.info.threshold then
				GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), MYTHIC_ITEM_LEVEL), GREEN_FONT_COLOR)
			else
				GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), MYTHIC_ITEM_LEVEL))
			end
		end
	end
	if numHeroic > 0 then
		for i = 1, numHeroic do
			if i == numMythicPlus + numMythic + numHeroic or i == self.info.threshold then
				GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_HEROIC, HEROIC_ITEM_LEVEL), GREEN_FONT_COLOR)
			else
				GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_HEROIC, HEROIC_ITEM_LEVEL))
			end
		end
	end
end

-- earned reward tooltips, as well as run history on the top tier
local HandleEarnedMythicRewardTooltip = function(self, blizzItemLevel)
	local apiItemLevel = 0
	if DifficultyUtil.ID.DungeonChallenge == C_WeeklyRewards.GetDifficultyIDForActivityTier(self.info.activityTierID) then
		apiItemLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(self.info.level)
	end
	local itemLevel = apiItemLevel > 0 and apiItemLevel or blizzItemLevel
	local isHeroicLevel = self:IsCompletedAtHeroicLevel()
	if isHeroicLevel then
		GameTooltip_AddNormalLine(GameTooltip, string.format(WEEKLY_REWARDS_ITEM_LEVEL_HEROIC, itemLevel))
	else
		GameTooltip_AddNormalLine(GameTooltip, string.format(WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, itemLevel, self.info.level))
	end
	local hasData, nextActivityTierID, nextLevel, nextItemLevel = C_WeeklyRewards.GetNextActivitiesIncrease(self.info.activityTierID, self.info.level)
	if hasData and DifficultyUtil.ID.DungeonChallenge == C_WeeklyRewards.GetDifficultyIDForActivityTier(nextActivityTierID) then
		-- GetNextActivitiesIncrease just returns current level + 1 as next level, have to use GetNextMythicPlusIncrease to get useful data
		hasData, nextLevel, nextItemLevel = C_WeeklyRewards.GetNextMythicPlusIncrease(self.info.level)
	end
	if hasData and nextLevel and nextItemLevel then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddColoredLine(GameTooltip, string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, nextItemLevel), GREEN_FONT_COLOR)
		if self.info.threshold == 1 then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, nextLevel))
		else
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_COMPLETE_MYTHIC, nextLevel, self.info.threshold))
		end
	end
	local runHistory = C_MythicPlus.GetRunHistory(false, true)
	local numHeroic, numMythic, numMythicPlus = C_WeeklyRewards.GetNumCompletedDungeonRuns()
	local numDungeons = numHeroic + numMythic + numMythicPlus
	if numDungeons > 0 then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		if self.info.threshold == calcMaxRewardThreshold and numDungeons > calcMaxRewardThreshold then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(L.top_runs_this_week, self.info.threshold, numDungeons))
		elseif self.info.threshold ~= 1 then
			GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, self.info.threshold))
		end
	end
	if #runHistory > 0 then
		local comparison = function(entry1, entry2)
			if entry1.level == entry2.level then
				return entry1.mapChallengeModeID < entry2.mapChallengeModeID
			else
				return entry1.level > entry2.level
			end
		end
		table.sort(runHistory, comparison)
		local maxLines = self.info.threshold == calcMaxRewardThreshold and #runHistory or self.info.threshold
		for i = 1, maxLines do
			if runHistory[i] then
				local runInfo = runHistory[i]
				local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID)
				local rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(runInfo.level)
				if i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel), GREEN_FONT_COLOR)
				elseif i > self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel), GRAY_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel))
				end
			end
		end
	end
	local HEROIC_ITEM_LEVEL, MYTHIC_ITEM_LEVEL = GetCurrentSeasonRewardLevels()
	if numMythic > 0 then
		local maxLines = self.info.threshold == calcMaxRewardThreshold and numMythicPlus + numMythic or self.info.threshold
		for i = numMythicPlus + 1, maxLines do
			if i == self.info.threshold then
				GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), MYTHIC_ITEM_LEVEL), GREEN_FONT_COLOR)
			elseif i > self.info.threshold then
				GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), MYTHIC_ITEM_LEVEL), GRAY_FONT_COLOR)
			else
				GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), MYTHIC_ITEM_LEVEL))
			end
		end
	end
	if numHeroic > 0 then
		local maxLines = self.info.threshold == calcMaxRewardThreshold and numDungeons or self.info.threshold
		for i = numMythicPlus + numMythic + 1, maxLines do
			if i == self.info.threshold then
				GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_HEROIC, HEROIC_ITEM_LEVEL), GREEN_FONT_COLOR)
			elseif i > self.info.threshold then
				GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_HEROIC, HEROIC_ITEM_LEVEL), GRAY_FONT_COLOR)
			else
				GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$d) %1$s", WEEKLY_REWARDS_HEROIC, HEROIC_ITEM_LEVEL))
			end
		end
	end
end

-- overrides CanShowPreviewItemTooltip
-- original: https://github.com/BigWigsMods/WoWUI/blob/live/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua
local CanShowPreviewItemTooltip = function(self)
	return self.info and not C_WeeklyRewards.CanClaimRewards()
end

-- overrides ShowPreviewItemTooltip
-- original: https://github.com/BigWigsMods/WoWUI/blob/live/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua
local ShowPreviewItemTooltip = function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -7, -11)
	GameTooltip_SetTitle(GameTooltip, WEEKLY_REWARDS_CURRENT_REWARD)
	local itemLink, upgradeItemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(self.info.id)
	local itemLevel, upgradeItemLevel
	if itemLink then
		itemLevel = GetDetailedItemLevelInfo(itemLink)
	end
	if upgradeItemLink then
		upgradeItemLevel = GetDetailedItemLevelInfo(upgradeItemLink)
	end
	if not itemLevel and not self.unlocked then
		HandleInProgressMythicRewardTooltip(self)
	else
		self.UpdateTooltip = nil
		if self.info.type == Enum.WeeklyRewardChestThresholdType.Raid then
			self:HandlePreviewRaidRewardTooltip(itemLevel, upgradeItemLevel)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.Activities then
			HandleEarnedMythicRewardTooltip(self, itemLevel)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
			self:HandlePreviewPvPRewardTooltip(itemLevel, upgradeItemLevel)
		end
		if not upgradeItemLevel then
			GameTooltip_AddBlankLineToTooltip(GameTooltip)
			GameTooltip_AddHighlightLine(GameTooltip, WEEKLY_REWARDS_MAXED_REWARD)
		end
	end
	GameTooltip:Show()
end

-- overrides SetProgressText
-- original: https://github.com/BigWigsMods/WoWUI/blob/live/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua
local SetProgressText = function(self, text)
	local activityInfo = self.info
	if text then
		self.Progress:SetText(text)
	elseif self.hasRewards then
		self.Progress:SetText(nil)
	elseif self.unlocked then
		if activityInfo.type == Enum.WeeklyRewardChestThresholdType.Raid then
			local name = DifficultyUtil.GetDifficultyName(activityInfo.level)
			self.Progress:SetText(name)
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.Activities then
			local HEROIC_ITEM_LEVEL, MYTHIC_ITEM_LEVEL = GetCurrentSeasonRewardLevels()
			if self:IsCompletedAtHeroicLevel() then
				self.Progress:SetFormattedText("(%d) "..WEEKLY_REWARDS_HEROIC, HEROIC_ITEM_LEVEL)
			else
				local rewardLevel
				if activityInfo.level >= 2 then
					rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(activityInfo.level)
				else
					rewardLevel = MYTHIC_ITEM_LEVEL
				end
				self.Progress:SetFormattedText("(%d) "..WEEKLY_REWARDS_MYTHIC, rewardLevel, activityInfo.level)
			end
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
			self.Progress:SetText(PVPUtil.GetTierName(activityInfo.level))
		end
	else
		if C_WeeklyRewards.CanClaimRewards() then
			-- no progress on incomplete activites during claiming
			self.Progress:SetText(nil)
		else
			self.Progress:SetFormattedText(GENERIC_FRACTION_STRING, activityInfo.progress, activityInfo.threshold)
		end
	end
end

WeeklyRewardsFrame.Activities[5].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[5].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[5].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[6].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[6].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[6].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[7].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[7].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[7].SetProgressText = SetProgressText
