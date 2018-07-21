local current_timestamp_ms = tonumber(ARGV[1])
local tokens_per_ms        = tonumber(ARGV[2])
local bucket_size          = tonumber(ARGV[3])
local new_content          = tonumber(ARGV[3])
local tokens_to_take       = tonumber(ARGV[4])
local ttl                  = tonumber(ARGV[5])

local current = redis.pcall('HMGET', KEYS[1], 'd', 'r')

if current.err ~= nil then
    current = {}
end

if current[1] and tokens_per_ms then
    -- drip bucket
    local last_drip = current[1]
    local content = current[2]
    local delta_ms = math.max(current_timestamp_ms - last_drip, 0)
    local drip_amount = delta_ms * tokens_per_ms
    new_content = math.min(content + drip_amount, bucket_size)
elseif current[1] and tokens_per_ms == 0 then
    -- fixed bucket
    new_content = current[2]
end

local enough_tokens = new_content >= tokens_to_take

if enough_tokens then
    new_content = math.min(new_content - tokens_to_take, bucket_size)
end

redis.call('HMSET', KEYS[1],
            'd', current_timestamp_ms,
            'r', new_content)
redis.call('EXPIRE', KEYS[1], ttl)

return { current_timestamp_ms, new_content, enough_tokens }
