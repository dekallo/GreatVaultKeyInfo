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
            GameTooltip_AddHighlightLine(GameTooltip, string.format("Top %1$d runs this week", self.info.threshold));
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

local HandleEarnedMythicRewardTooltip = function(self, itemLevel, upgradeItemLevel)
    GameTooltip_AddNormalLine(GameTooltip, string.format(WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC, itemLevel, self.info.level));
    GameTooltip_AddBlankLineToTooltip(GameTooltip);
    if upgradeItemLevel then
        upgradeMythicLevel = self.info.level + 1;
        if upgradeItemLevel == itemLevel then
            for i = upgradeMythicLevel + 1, 15 do
                upgradeItemLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(self.info.level + i);
                if upgradeItemLevel > itemLevel then
                    upgradeMythicLevel = i;
                    break;
                end
            end
        end
        GameTooltip_AddColoredLine(GameTooltip, string.format(WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL, upgradeItemLevel), GREEN_FONT_COLOR);
        GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_COMPLETE_MYTHIC, upgradeMythicLevel, self.info.threshold));
    end
    local runHistory = C_MythicPlus.GetRunHistory(false, true);
    if #runHistory > 0 then
        GameTooltip_AddBlankLineToTooltip(GameTooltip);
        GameTooltip_AddHighlightLine(GameTooltip, string.format(WEEKLY_REWARDS_MYTHIC_TOP_RUNS, self.info.threshold));
        local comparison = function(entry1, entry2)
            if ( entry1.level == entry2.level ) then
                return entry1.mapChallengeModeID < entry2.mapChallengeModeID;
            else
                return entry1.level > entry2.level;
            end
        end
        table.sort(runHistory, comparison);
        for i = 1, self.info.threshold do
            if runHistory[i] then
                local runInfo = runHistory[i];
                local name = C_ChallengeMode.GetMapUIInfo(runInfo.mapChallengeModeID);
                local rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(runInfo.level);
                if i == self.info.threshold then
                    GameTooltip_AddColoredLine(GameTooltip, string.format("(%3$d) %1$d - %2$s", runInfo.level, name, rewardLevel), GREEN_FONT_COLOR);
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
            HandleEarnedMythicRewardTooltip(self, itemLevel, upgradeItemLevel);
        elseif self.info.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
            self:HandlePreviewPvPRewardTooltip(itemLevel, upgradeItemLevel);
        end
        if not upgradeItemLevel then
            GameTooltip_AddBlankLineToTooltip(GameTooltip);
            GameTooltip_AddColoredLine(GameTooltip, WEEKLY_REWARDS_MAXED_REWARD, GREEN_FONT_COLOR);
        end
    end
    GameTooltip:Show();
end

WeeklyRewardsFrame.Activities[5].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[5].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[6].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[6].ShowPreviewItemTooltip = ShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[7].CanShowPreviewItemTooltip = CanShowPreviewItemTooltip
WeeklyRewardsFrame.Activities[7].ShowPreviewItemTooltip = ShowPreviewItemTooltip