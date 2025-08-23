-- globals
local C_MythicPlus, C_ChallengeMode, C_WeeklyRewards = C_MythicPlus, C_ChallengeMode, C_WeeklyRewards
local C_Item, DifficultyUtil, PVPUtil, CreateFrame, max, tostring = C_Item, DifficultyUtil, PVPUtil, CreateFrame, max, tostring
local WeeklyRewardsFrame, GameTooltip, Enum = WeeklyRewardsFrame, GameTooltip, Enum
local GameTooltip_SetTitle, GameTooltip_AddNormalLine, GameTooltip_AddHighlightLine, GameTooltip_AddColoredLine, GameTooltip_AddBlankLineToTooltip = GameTooltip_SetTitle, GameTooltip_AddNormalLine, GameTooltip_AddHighlightLine, GameTooltip_AddColoredLine, GameTooltip_AddBlankLineToTooltip
local WEEKLY_REWARDS_MYTHIC_TOP_RUNS, WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, WEEKLY_REWARDS_COMPLETE_MYTHIC = WEEKLY_REWARDS_MYTHIC_TOP_RUNS, WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, WEEKLY_REWARDS_COMPLETE_MYTHIC
local WEEKLY_REWARDS_HEROIC, WEEKLY_REWARDS_MYTHIC, WEEKLY_REWARDS_MAXED_REWARD, WEEKLY_REWARDS_CURRENT_REWARD, WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, WEEKLY_REWARDS_ITEM_LEVEL_HEROIC = WEEKLY_REWARDS_HEROIC, WEEKLY_REWARDS_MYTHIC, WEEKLY_REWARDS_MAXED_REWARD, WEEKLY_REWARDS_CURRENT_REWARD, WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, WEEKLY_REWARDS_ITEM_LEVEL_HEROIC
local GREEN_FONT_COLOR, GRAY_FONT_COLOR, GENERIC_FRACTION_STRING, GREAT_VAULT_WORLD_TIER = GREEN_FONT_COLOR, GRAY_FONT_COLOR, GENERIC_FRACTION_STRING, GREAT_VAULT_WORLD_TIER
local WeeklyRewardsUtil = WeeklyRewardsUtil
local L = LibStub("AceLocale-3.0"):GetLocale("GreatVaultKeyInfo")

-- locals
local RaidItemLevelsBySeason = {
	-- The War Within Season 3
	[108] = {
		[17] = 671, -- LFR
		[14] = 684, -- Normal
		[15] = 697, -- Heroic
		[16] = 710, -- Mythic
	},
}
-- this is from https://wago.tools/db2/MythicPlusSeasonRewardLevels?page=1&sort[WeeklyRewardLevel]=asc&filter[MythicPlusSeasonID]=108
local DungeonItemLevelsBySeason = {
	-- The War Within Season 3
	[108] = {
		["HEROIC"] = 678,
		["MYTHIC"] = 691,
		[2] = 694,
		[3] = 694,
		[4] = 697,
		[5] = 697,
		[6] = 701,
		[7] = 704,
		[8] = 704,
		[9] = 704,
		[10] = 707,
	},
}
local WorldItemLevelsBySeason = {
	-- The War Within Season 3
	[108] = {
		[1] = 668,
		[2] = 671,
		[3] = 675,
		[4] = 678,
		[5] = 681,
		[6] = 688,
		[7] = 691,
		[8] = 694,
	},
}
-- the order of entries in this table matters, must be highest tier to lowest tier
local ItemTiers = {
	"myth",
	"hero",
	"champion",
	"veteran",
	"adventurer",
	--"explorer", we don't care about explorer because it can't be rewarded in the vault
}
-- this is the minimum starting item level to go up a tier
local ItemTierItemMinimumLevelBySeason = {
	-- The War Within Season 3
	[108] = {
		["adventurer"] = 655,
		["veteran"] = 668,
		["champion"] = 681,
		["hero"] = 694,
		["myth"] = 707,
	},
}
-- ranks within each tier
local ItemTierItemLevelsBySeason = {
	-- The War Within Season 3
	[108] = {
		["adventurer"] = {
			[655] = 1,
			[658] = 2,
			[662] = 3,
			[665] = 4,
			[668] = 5,
			[671] = 6,
			[675] = 7,
			[678] = 8,
		},
		["veteran"] = {
			[668] = 1,
			[671] = 2,
			[675] = 3,
			[678] = 4,
			[681] = 5,
			[684] = 6,
			[688] = 7,
			[691] = 8,
		},
		["champion"] = {
			[681] = 1,
			[684] = 2,
			[688] = 3,
			[691] = 4,
			[694] = 5,
			[697] = 6,
			[701] = 7,
			[704] = 8,
		},
		["hero"] = {
			[694] = 1,
			[697] = 2,
			[701] = 3,
			[704] = 4,
			[707] = 5,
			[710] = 6,
		},
		["myth"] = {
			[707] = 1,
			[710] = 2,
			[714] = 3,
			[717] = 4,
			[720] = 5,
			[723] = 6,
		},
	},
}
local ItemTierNumRanksBySeason = {
	-- The War Within Season 3
	[108] = {
		["adventurer"] = 8,
		["veteran"] = 8,
		["champion"] = 8,
		["hero"] = 6,
		["myth"] = 6,
	},
}
-- fallback value
local WEEKLY_MAX_DUNGEON_THRESHOLD = 8

-- event frame
local GreatVaultKeyInfoFrame = CreateFrame("Frame")
GreatVaultKeyInfoFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
GreatVaultKeyInfoFrame:SetScript("OnEvent", function(self, event_name, ...)
	if self[event_name] then
		return self[event_name](self, event_name, ...)
	end
end)

-- utility functions
local GetRewardSeasonID = function()
	local _, _, rewardSeasonID = C_MythicPlus.GetCurrentSeasonValues()
	return rewardSeasonID
end
local GetItemTierFromItemLevel = function(itemLevel)
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonItemTiers = ItemTierItemMinimumLevelBySeason[rewardSeasonID]
	if currentSeasonItemTiers then
		for _, itemTierKey in ipairs(ItemTiers) do
			local itemTierItemLevel = currentSeasonItemTiers[itemTierKey]
			if itemLevel >= itemTierItemLevel then
				local rank = ItemTierItemLevelsBySeason[rewardSeasonID][itemTierKey][itemLevel]
				local maxRank = ItemTierNumRanksBySeason[rewardSeasonID][itemTierKey]
				return ("%d - %d/%d %s"):format(itemLevel, rank, maxRank, L[itemTierKey])
			end
		end
	end
	return tostring(itemLevel)
end
local GetCurrentSeasonRewardLevels = function()
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonRewardLevels = DungeonItemLevelsBySeason[rewardSeasonID]
	if currentSeasonRewardLevels then
		return currentSeasonRewardLevels.HEROIC, currentSeasonRewardLevels.MYTHIC
	end
end
local GetRewardLevelFromRaidLevel = function(raidLevel, blizzItemLevel)
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonRewardLevels = RaidItemLevelsBySeason[rewardSeasonID]
	if currentSeasonRewardLevels then
		return currentSeasonRewardLevels[raidLevel] or blizzItemLevel or 0
	end
	return blizzItemLevel or 0
end
local GetRewardLevelFromKeystoneLevel = function(keystoneLevel, blizzItemLevel)
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonRewardLevels = DungeonItemLevelsBySeason[rewardSeasonID]
	if currentSeasonRewardLevels then
		if keystoneLevel > 10 then
			keystoneLevel = 10
		end
		return currentSeasonRewardLevels[keystoneLevel] or blizzItemLevel or 0
	end
	-- as a fallback use Blizzard's unreliable API
	return blizzItemLevel or C_MythicPlus.GetRewardLevelFromKeystoneLevel(keystoneLevel) or 0
end
local GetRewardLevelFromDelveLevel = function(delveLevel, blizzItemLevel)
	local rewardSeasonID = GetRewardSeasonID()
	local currentSeasonRewardLevels = WorldItemLevelsBySeason[rewardSeasonID]
	if currentSeasonRewardLevels then
		if delveLevel > 8 then
			delveLevel = 8
		end
		return currentSeasonRewardLevels[delveLevel] or blizzItemLevel or 0
	end
	return blizzItemLevel or 0
end
local CompareRuns = function(entry1, entry2)
	if entry1.level == entry2.level then
		return entry1.mapChallengeModeID < entry2.mapChallengeModeID
	else
		return entry1.level > entry2.level
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
local HandleInProgressDungeonRewardTooltip = function(self)
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
		table.sort(runHistory, CompareRuns)
		for i = 1, #runHistory do
			if runHistory[i] then
				local runInfo = runHistory[i]
				local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID)
				local rewardLevel = GetRewardLevelFromKeystoneLevel(runInfo.level)
				if i == #runHistory or i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)), GREEN_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)))
				end
			end
		end
	end
	if numMythic > 0 or numHeroic > 0 then
		local HEROIC_ITEM_LEVEL, MYTHIC_ITEM_LEVEL = GetCurrentSeasonRewardLevels()
		if numMythic > 0 then
			for i = 1, numMythic do
				if i == numMythicPlus + numMythic or i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)), GREEN_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)))
				end
			end
		end
		if numHeroic > 0 then
			for i = 1, numHeroic do
				if i == numMythicPlus + numMythic + numHeroic or i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)), GREEN_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)))
				end
			end
		end
	end
end

-- earned reward tooltips, as well as run history on the top tier
local HandleEarnedDungeonRewardTooltip = function(self, blizzItemLevel)
	local itemLevel
	if DifficultyUtil.ID.DungeonChallenge == C_WeeklyRewards.GetDifficultyIDForActivityTier(self.info.activityTierID) then
		itemLevel = GetRewardLevelFromKeystoneLevel(self.info.level, blizzItemLevel)
	else
		itemLevel = blizzItemLevel
	end
	if self:IsCompletedAtHeroicLevel() then
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
		table.sort(runHistory, CompareRuns)
		local maxLines = self.info.threshold == calcMaxRewardThreshold and #runHistory or self.info.threshold
		for i = 1, maxLines do
			if runHistory[i] then
				local runInfo = runHistory[i]
				local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID)
				local rewardLevel = GetRewardLevelFromKeystoneLevel(runInfo.level)
				if i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)), GREEN_FONT_COLOR)
				elseif i > self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)), GRAY_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%3$s) %1$d - %2$s", runInfo.level, name, GetItemTierFromItemLevel(rewardLevel)))
				end
			end
		end
	end
	if numMythic > 0 or numHeroic > 0 then
		local HEROIC_ITEM_LEVEL, MYTHIC_ITEM_LEVEL = GetCurrentSeasonRewardLevels()
		if numMythic > 0 then
			local maxLines = self.info.threshold == calcMaxRewardThreshold and numMythicPlus + numMythic or self.info.threshold
			for i = numMythicPlus + 1, maxLines do
				if i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)), GREEN_FONT_COLOR)
				elseif i > self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)), GRAY_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel), GetItemTierFromItemLevel(MYTHIC_ITEM_LEVEL)))
				end
			end
		end
		if numHeroic > 0 then
			local maxLines = self.info.threshold == calcMaxRewardThreshold and numDungeons or self.info.threshold
			for i = numMythicPlus + numMythic + 1, maxLines do
				if i == self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)), GREEN_FONT_COLOR)
				elseif i > self.info.threshold then
					GameTooltip_AddColoredLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)), GRAY_FONT_COLOR)
				else
					GameTooltip_AddHighlightLine(GameTooltip, string.format("(%2$s) %1$s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL)))
				end
			end
		end
	end
end

local AddWorldProgress = function(threshold)
	local activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.World)
	local activity = activities[1]
	if activity and activity.level and activity.level > 0 then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, threshold))
		local previousActivityProgress = 0
		for i = 1, 3 do
			activity = activities[i]
			if activity and activity.level and activity.level > 0 then
				local maxProgress = min(activity.progress, threshold)
				if previousActivityProgress < maxProgress then
					local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activity.id)
					local itemLevel = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink) or nil
					local reward = GetItemTierFromItemLevel(GetRewardLevelFromDelveLevel(activity.level, itemLevel))
					local tier = GREAT_VAULT_WORLD_TIER:format(activity.level)
					local rewardText = string.format("(%s) %s", reward, tier)
					for j = previousActivityProgress + 1, maxProgress do
						if j == threshold or j == activities[3].progress then
							GameTooltip_AddColoredLine(GameTooltip, rewardText, GREEN_FONT_COLOR)
						else
							GameTooltip_AddHighlightLine(GameTooltip, rewardText)
						end
					end
					previousActivityProgress = activity.progress
				end
			end
		end
	end
end

local ShowIncompleteWorldTooltip = function(self, title, description)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -7, -11)
	GameTooltip_SetTitle(GameTooltip, title)
	GameTooltip_AddNormalLine(GameTooltip, description:format(self.info.threshold - self.info.progress))
	AddWorldProgress(self.info.threshold)
	GameTooltip:Show()
end

local HandlePreviewWorldRewardTooltip = function(self, itemLevel, upgradeItemLevel, nextLevel)
	GameTooltip_AddNormalLine(GameTooltip, string.format(WEEKLY_REWARDS_ITEM_LEVEL_WORLD, itemLevel, self.info.level))
	if upgradeItemLevel then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddColoredLine(GameTooltip, string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, upgradeItemLevel), GREEN_FONT_COLOR)
		GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_COMPLETE_WORLD, nextLevel))
	end
	AddWorldProgress(self.info.threshold)
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
		itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
	end
	if upgradeItemLink then
		upgradeItemLevel = C_Item.GetDetailedItemLevelInfo(upgradeItemLink)
	end
	if not itemLevel and not self.unlocked then
		if self.info.type == Enum.WeeklyRewardChestThresholdType.Activities then
			HandleInProgressDungeonRewardTooltip(self)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.World then
			local description = GREAT_VAULT_REWARDS_WORLD_INCOMPLETE
			if self.info.index == 2 then
				description = GREAT_VAULT_REWARDS_WORLD_COMPLETED_FIRST
			elseif self.info.index == 3 then
				description = GREAT_VAULT_REWARDS_WORLD_COMPLETED_SECOND
			end
			ShowIncompleteWorldTooltip(self, WEEKLY_REWARDS_UNLOCK_REWARD, description)
		end
	else
		self.UpdateTooltip = nil
		if self.info.type == Enum.WeeklyRewardChestThresholdType.Raid then
			self:HandlePreviewRaidRewardTooltip(itemLevel, upgradeItemLevel)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.Activities then
			HandleEarnedDungeonRewardTooltip(self, itemLevel)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
			self:HandlePreviewPvPRewardTooltip(itemLevel, upgradeItemLevel)
		elseif self.info.type == Enum.WeeklyRewardChestThresholdType.World then
			local hasData, _, nextLevel, nextItemLevel = C_WeeklyRewards.GetNextActivitiesIncrease(self.info.activityTierID, self.info.level)
			if hasData then
				upgradeItemLevel = nextItemLevel
			else
				nextLevel = self.info.level + 1
			end
			HandlePreviewWorldRewardTooltip(self, itemLevel, upgradeItemLevel, nextLevel)
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
			local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activityInfo.id)
			local itemLevel = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink) or nil
			local rewardLevel = GetRewardLevelFromRaidLevel(activityInfo.level, itemLevel)
			self.Progress:SetJustifyH("RIGHT")
			self.Progress:SetFormattedText("%s\n%s", DifficultyUtil.GetDifficultyName(activityInfo.level), GetItemTierFromItemLevel(rewardLevel))
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.Activities then
			local HEROIC_ITEM_LEVEL, MYTHIC_ITEM_LEVEL = GetCurrentSeasonRewardLevels()
			self.Progress:SetJustifyH("RIGHT")
			if self:IsCompletedAtHeroicLevel() then
				self.Progress:SetFormattedText("%s\n%s", WEEKLY_REWARDS_HEROIC, GetItemTierFromItemLevel(HEROIC_ITEM_LEVEL))
			elseif activityInfo.level >= 2 then
				local rewardLevel = GetRewardLevelFromKeystoneLevel(activityInfo.level)
				self.Progress:SetFormattedText("+%d\n%s", activityInfo.level, GetItemTierFromItemLevel(rewardLevel))
			else
				local rewardLevel = MYTHIC_ITEM_LEVEL
				self.Progress:SetFormattedText("%s\n%s", WEEKLY_REWARDS_MYTHIC:format(activityInfo.level), GetItemTierFromItemLevel(rewardLevel))
			end
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
			self.Progress:SetText(PVPUtil.GetTierName(activityInfo.level))
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.World then
			local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activityInfo.id)
			local itemLevel = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink) or nil
			local rewardLevel = GetRewardLevelFromDelveLevel(activityInfo.level, itemLevel)
			self.Progress:SetJustifyH("RIGHT")
			self.Progress:SetFormattedText("%s\n%s", GREAT_VAULT_WORLD_TIER:format(activityInfo.level), GetItemTierFromItemLevel(rewardLevel))
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

-- Raid
WeeklyRewardsFrame.Activities[2].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[3].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[4].SetProgressText = SetProgressText

-- Dungeons
WeeklyRewardsFrame.Activities[5].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[5].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[5].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[6].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[6].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[6].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[7].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[7].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[7].SetProgressText = SetProgressText

-- World
WeeklyRewardsFrame.Activities[8].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[8].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[8].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[9].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[9].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[9].SetProgressText = SetProgressText
WeeklyRewardsFrame.Activities[10].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[10].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[10].SetProgressText = SetProgressText
