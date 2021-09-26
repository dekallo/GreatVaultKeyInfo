local addonName, addon = ...

-- globals
local C_MythicPlus, C_ChallengeMode, GetDetailedItemLevelInfo = C_MythicPlus, C_ChallengeMode, GetDetailedItemLevelInfo

-- TODO overriding WeeklyRewardsFrame.Activities[7] is dumb, i guess

-- always show tooltip
local CanShowPreviewItemTooltip = function(self)
    return not C_WeeklyRewards.CanClaimRewards();
end

local HandleInProgressMythicRewardTooltip = function(self)
    GameTooltip_SetTitle(GameTooltip, "Reward Locked");
    local runHistory = C_MythicPlus.GetRunHistory(false, true);
    GameTooltip_AddNormalLine(GameTooltip, string.format("Run %1$d more to unlock", self.info.threshold - #runHistory));
    if #runHistory > 0 then
        GameTooltip_AddBlankLineToTooltip(GameTooltip);
        if (self.info.threshold == 10) then
            GameTooltip_AddHighlightLine(GameTooltip, string.format(#runHistory == 1 and "%1$d run this week" or "%1$d runs this week", #runHistory));
        else
            GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, self.info.threshold));
        end
        local comparison = function(entry1, entry2)
            if ( entry1.level == entry2.level ) then
                return entry1.mapChallengeModeID < entry2.mapChallengeModeID;
            else
                return entry1.level > entry2.level;
            end
        end
        table.sort(runHistory, comparison);
        for i = 1, #runHistory do
            if runHistory[i] then
                local runInfo = runHistory[i];
                local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID);
                local rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(runInfo.level);
                if i == #runHistory or i == self.info.threshold then
                    GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel), GREEN_FONT_COLOR);
                else
                    GameTooltip_AddHighlightLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel));
                end
            end
        end
    end
end

local HandleEarnedMythicRewardTooltip = function(self, itemLevel)
    GameTooltip_AddNormalLine(GameTooltip, string.format(WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, itemLevel, self.info.level));
    local hasData, nextLevel, nextItemLevel = C_WeeklyRewards.GetNextMythicPlusIncrease(self.info.level);
    if hasData and nextLevel and nextItemLevel then
        GameTooltip_AddBlankLineToTooltip(GameTooltip);
        GameTooltip_AddColoredLine(GameTooltip, string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, nextItemLevel), GREEN_FONT_COLOR);
        if self.info.threshold == 1 then
            GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT, nextLevel));
        else
            GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_COMPLETE_MYTHIC, nextLevel, self.info.threshold));
        end
    end
    local runHistory = C_MythicPlus.GetRunHistory(false, true);
    if #runHistory > 0 then
        GameTooltip_AddBlankLineToTooltip(GameTooltip);
        if self.info.threshold == 10 and #runHistory > 10 then
            GameTooltip_AddHighlightLine(GameTooltip, string.format("Top %d of %d Runs This Week", self.info.threshold, #runHistory));
        elseif self.info.threshold ~= 1 then
            GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, self.info.threshold));
        end
        local comparison = function(entry1, entry2)
            if ( entry1.level == entry2.level ) then
                return entry1.mapChallengeModeID < entry2.mapChallengeModeID;
            else
                return entry1.level > entry2.level;
            end
        end
        table.sort(runHistory, comparison);
        local maxLines = self.info.threshold == 10 and #runHistory or self.info.threshold
        for i = 1, maxLines do
            if runHistory[i] then
                local runInfo = runHistory[i];
                local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID);
                local rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(runInfo.level);
                if i == self.info.threshold then
                    GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel), GREEN_FONT_COLOR);
                elseif i > self.info.threshold then
                    GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel), GRAY_FONT_COLOR);
                else
                    GameTooltip_AddHighlightLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel));
                end
            end
        end
    end
end

-- https://github.com/Gethe/wow-ui-source/blob/live/AddOns/Blizzard_WeeklyRewards/Blizzard_WeeklyRewards.lua
local ShowPreviewItemTooltip = function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -7, -11);
    GameTooltip_SetTitle(GameTooltip, WEEKLY_REWARDS_CURRENT_REWARD);
    local itemLink, upgradeItemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(self.info.id);
    local itemLevel, upgradeItemLevel;
    if itemLink then
        itemLevel = GetDetailedItemLevelInfo(itemLink);
    end
    if upgradeItemLink then
        upgradeItemLevel = GetDetailedItemLevelInfo(upgradeItemLink);
    end
    if not itemLevel and not self.unlocked then
        HandleInProgressMythicRewardTooltip(self);
    else
        self.UpdateTooltip = nil;
        if self.info.type == Enum.WeeklyRewardChestThresholdType.Raid then
            self:HandlePreviewRaidRewardTooltip(itemLevel, upgradeItemLevel);
        elseif self.info.type == Enum.WeeklyRewardChestThresholdType.MythicPlus then
            HandleEarnedMythicRewardTooltip(self, itemLevel);
        elseif self.info.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
            self:HandlePreviewPvPRewardTooltip(itemLevel, upgradeItemLevel);
        end
        if not upgradeItemLevel then
            GameTooltip_AddBlankLineToTooltip(GameTooltip);
            GameTooltip_AddHighlightLine(GameTooltip, WEEKLY_REWARDS_MAXED_REWARD);
        end
    end
    GameTooltip:Show();
end

local SetProgressText = function(self, text)
	local activityInfo = self.info;
	if text then
		self.Progress:SetText(text);
	elseif self.hasRewards then
		self.Progress:SetText(nil);
	elseif self.unlocked then
		if activityInfo.type == Enum.WeeklyRewardChestThresholdType.Raid then
			local name = DifficultyUtil.GetDifficultyName(activityInfo.level);
			self.Progress:SetText(name);
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.MythicPlus then
            local rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(activityInfo.level);
			self.Progress:SetFormattedText("(%d) "..WEEKLY_REWARDS_MYTHIC, rewardLevel, activityInfo.level);
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
			self.Progress:SetText(PVPUtil.GetTierName(activityInfo.level));
		end
	else
		if C_WeeklyRewards.CanClaimRewards() then
			-- no progress on incomplete activites during claiming
			self.Progress:SetText(nil);
		else
			self.Progress:SetFormattedText(GENERIC_FRACTION_STRING, activityInfo.progress, activityInfo.threshold);
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
