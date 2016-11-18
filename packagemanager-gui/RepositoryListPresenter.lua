local misc = require 'packagemanager/misc'
local version = require 'packagemanager/version'
local PackageManager = require 'packagemanager/init'
local Event = require 'packagemanager-gui/Event'


local RepositoryListPresenter = {}
RepositoryListPresenter.__index = RepositoryListPresenter

function RepositoryListPresenter:destroy()
end

return function( view, mainPresenter )
    local self = setmetatable({}, RepositoryListPresenter)
    self.view = view

    view.addRepositoryEvent:addListener(function()
        view:freeze()
        view:addRepository('')
        view:enableApplyButton(true)
        view:thaw()
    end)

    view.removeRepositoryEvent:addListener(function( entry, url )
        view:freeze()
        view:removeRepository(entry)
        view:enableApplyButton(true)
        view:thaw()
    end)

    view.changeRepositoryEvent:addListener(function( entry, url )
        view:freeze()
        view:enableApplyButton(true)
        view:thaw()
    end)

    view.applyButtonPressEvent:addListener(function()
        local urls = view:getRepositoryUrls()
        PackageManager.setRepositories(urls)

        mainPresenter:updateRepositoryIndices()

        view:freeze()
        view:enableApplyButton(false)
        view:thaw()
    end)

    view:freeze()
    for _, url in ipairs(PackageManager.getRepositories()) do
        view:addRepository(url)
    end
    view:enableApplyButton(false)
    view:thaw()

    return self
end
