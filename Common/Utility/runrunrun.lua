-- yonderboi <3 Maxxxel :P
--
-- throttling/scheduling function wrappers
-- v01 - 4/26/2013 3:08:51 PM - tested in lua 5.1 and 5.2
-- v02 - 4/26/2013 6:01:44 PM - reset functionality, while/until, wrote example script
-- v03 - 4/27/2013 12:11:32 PM - rename reset functions from reset_* to *_reset
-- v04 - 6/14/2014 11:45 AM - commented a couple prints

-- todo: allow optional string keys
    
local _registry = {}

function run_once(fn, ...)
    return run_many(1, fn, ...)
end

function run_many(count, fn, ...)
    return internal_run({fn=fn, count=count}, ...)
end

function run_many_reset(count, fn, ...)
    return internal_run({fn=fn, count=count, reset=true}, ...)
end

function run_every(interval, fn, ...)
    return internal_run({fn=fn, interval=interval}, ...)
end

function run_every_reset(interval, fn, ...)
    return internal_run({fn=fn, interval=interval, reset=true}, ...)
end

function run_later(seconds, fn, ...)
    return internal_run({fn=fn, count=1, start=os.clock()+seconds}, ...)
end

function run_later_reset(seconds, fn, ...)
    return internal_run({fn=fn, count=1, start=os.clock()+seconds, reset=true}, ...)
end

function run_at(clock, fn, ...)
    return internal_run({fn=fn, count=1, start=clock}, ...)
end

function run_at_reset(clock, fn, ...)
    return internal_run({fn=fn, count=1, start=clock, reset=true}, ...)
end

-- run fn until it returns true
function run_until(fn, ...)
    return internal_run({fn=fn, _until=fn})
end

-- run fn as long as it returns true
function run_while(fn, ...)
    return internal_run({fn=fn, _while=fn})
end

-- run fn until untilfn returns true
function run_until2(untilfn, fn, ...)
    return internal_run({fn=fn, _until=untilfn})
end

-- run fn while whilefn returns true
function run_while2(whilefn, fn, ...)
    return internal_run({fn=fn, _while=whilefn})
end

-- resets for while/until
function run_until_reset(fn, ...)
    return internal_run({fn=fn, _until=fn, reset=true})
end

function run_while_reset(fn, ...)
    return internal_run({fn=fn, _while=fn, reset=true})
end

function run_until2_reset(untilfn, fn, ...)
    return internal_run({fn=fn, _until=untilfn, reset=true})
end

function run_while2_reset(whilefn, fn, ...)
    return internal_run({fn=fn, _while=whilefn, reset=true})
end

-- technically optional, but recommended
-- run checks at different places in code, make code more clear
-- key is key or fn
-- if args are passed, then they are used in latest call, else original args are used
function run_check(key, ...)        
    local data = _registry[key]
    if data==nil then
        -- print('attempted run_check with invalid key : '..tostring(key))
        return
    end
    local n = select('#', ...)
    local result
    if n>0 then
        result = internal_run(data.t, ...)
    else
        result = internal_run(data.t, unpack(data.args))
    end
    -- automatic cleanup for count~=nil items (only when using run_check)
    -- and for data.complete items
    if data.count >= data.t.count or data.complete then
        --print('autocleanup: '..tostring(key))
        unregister(key)
    end    
    return result
end

function run_check_all(...)
    local n = select('#', ...)
    for k,v in pairs(_registry) do
        data = _registry[k]
        if n>0 then
            internal_run(data.t, ...)
        else
            internal_run(data.t, unpack(data.args))
        end         
    end
end

-- mostly for internal use
function unregister(key)    
    _registry[key] = nil
    --print('key unregistered: '..tostring(key))
end

-- fn = the function to run (required)
-- count = how many times to run, nil for infinite (optional, default:nil)
-- start = the time to start runs (optional, default:nil)
-- interval = the seconds between runs (optional, default:nil)
-- key = key to use instead of fn (optional, default:fn)
-- reset = boolean, overwrites existing init data, as if it were the first call (optional, default:nil)
function internal_run(t, ...)    
    local fn = t.fn
    local key = t.key or fn
    
    local now = os.clock()
    local data = _registry[key]
       
    if data == nil or t.reset then
        local args = {}
        local n = select('#', ...)
        local v
        for i=1,n do
            v = select(i, ...)
            table.insert(args, v)
        end   
        -- the first t and args are stored in registry        
        data = {count=0, last=0, complete=false, t=t, args=args}
        _registry[key] = data
    end
        
    --assert(data~=nil, 'data==nil')
    --assert(data.count~=nil, 'data.count==nil')
    --assert(now~=nil, 'now==nil')
    --assert(data.t~=nil, 'data.t==nil')
    --assert(data.t.start~=nil, 'data.t.start==nil')
    --assert(data.last~=nil, 'data.last==nil')
    -- run
    local countCheck = (t.count==nil or data.count < t.count)
    local startCheck = (data.t.start==nil or now >= data.t.start)
    local intervalCheck = (t.interval==nil or now-data.last >= t.interval)
    --print('', 'countCheck', tostring(countCheck))
    --print('', 'startCheck', tostring(startCheck))
    --print('', 'intervalCheck', tostring(intervalCheck))
    --print('')
    if not data.complete and countCheck and startCheck and intervalCheck then                
        if t.count ~= nil then -- only increment count if count matters
            data.count = data.count + 1
        end
        data.last = now        
        
        if t._while==nil and t._until==nil then
            return fn(...)
        else
            -- while/until handling
            local signal = t._until ~= nil
            local checker = t._while or t._until
            local result
            if fn == checker then            
                result = fn(...)
                if result == signal then
                    data.complete = true
                end
                return result
            else
                result = checker(...)
                if result == signal then
                    data.complete = true
                else
                    return fn(...)
                end
            end            
        end
    end    
end
