function tableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
  end
  
  -- Count the number of times a value occurs in a table ha
  function tableCount(tt, item)
    local count = 0
    for _,value in pairs(tt) do
      if item == value then count = count + 1 end
    end
    return count
  end
  
  function getInstancesState(loadBalancerInfo)
      local instancesState, status, type, rc = hs.execute("aws --profile " ..loadBalancerInfo["profile"] ..
      " elb describe-instance-health --load-balancer-name " .. loadBalancerInfo["loadBalancerName"] ..
      " --query 'InstanceStates[*].[State]' --output text" ..
      " --region " .. loadBalancerInfo["region"], true)
  
      if status == true then
          local instances = {}
          for instance in instancesState:gmatch("%S+") do table.insert(instances, instance) end
  
          local healthyInstances = tableCount(instances, "InService")
  
          local unhealthyInstances = tableCount(instances, "OutOfService")
  
          local percentage = (healthyInstances / tableLength(instances)) * 100
  
          return healthyInstances, unhealthyInstances, percentage, true
      else
          return "", "", 0.0, false
      end
  end
  
  function constructInterface()
      if caffeine then
          local menuItems = {}
          -- to update - Title in the menu bar of Mac OS
          local title = { "myService" }
          -- To update depending the application you are monitoring
          local loadBalancerMonitored = {
              { profile = "default", region = "eu-west-1", regionShort = "EU", loadBalancerName = "myLoadBalancer" }
          }
  
          for i = 1, #loadBalancerMonitored do
              healthyInstances, unhealthyInstances, percentage, status = getInstancesState(loadBalancerMonitored[i])
  
              if status == true then
                  menuItems[#menuItems+1] = { title = "- " .. loadBalancerMonitored[i]["regionShort"] .. " -", disabled = true }
                  menuItems[#menuItems+1] = { title = healthyInstances .. " healthy", disabled = true }
                  menuItems[#menuItems+1] = { title = unhealthyInstances .. " unhealthy", disabled = true }
  
                  table.insert(title, loadBalancerMonitored[i]["regionShort"] .. ": " .. percentage .. "%")
              end
          end
  
          if next(menuItems) == nil then
              caffeine:setTitle("Error")
          else
              caffeine:setMenu(menuItems)
              caffeine:setTitle(table.concat(title, " - "))
           end
      end
  end
  
  caffeine = hs.menubar.new()
  constructInterface()
  hs.timer.doEvery(300, constructInterface)
  