logger = {
    content = {},
    stylel = {},
    styles = {
        white = {r=255/255, g=255/255, b=255/255},
        red = {r=255/255,g=127/255,b=127/255},
        yellow = {r=255/255, g=255/255, b=127/255},
        green = {r=191/255, g=255/255, b=127/255},
        blue = {r=127/255, g=159/255, b=255/255},
        default = {r=224/255, g=224/255, b=224/255},
    },
    count = 0,
    limit = 32,
}

function logger.print(text, style)
    if (style == nil) then
        style = logger.styles.default
    end
    if (logger.count > logger.limit) then -- scroll elements
        table.remove(logger.content, 1)
        table.remove(logger.stylel, 1)
    else  -- add element
        logger.count = logger.count + 1
    end  -- write data:
    logger.content[logger.count] = text
    logger.stylel[logger.count] = style
end

function logger.debug(text)
    logger.print(text, logger.styles.default)
end

function logger.info(text)
    logger.print(text, logger.styles.green)
end

function logger.warning(text)
    logger.print(text, logger.styles.yellow)
end

function logger.error(text)
    logger.print(text, logger.styles.red)
end

function logger.draw(x, y)
    local index, style, text
    prefix = ''
    -- default position parameters:
    if (x == nil) then x = 16 end
    if (y == nil) then y = 16 end
    -- draw lines:
    for i = 1, logger.count do
    love.graphics.push()
        love.graphics.scale(0.5, 0.5)
        style = logger.stylel[i]
        text = prefix .. logger.content[i]
        -- choose white/black outline:
        if ((style.r < 160) and (style.g < 160) and (style.b < 160)) then
            love.graphics.setColor(255, 255, 255)
        else
            love.graphics.setColor(0, 0, 0)
        end
        -- draw outline:
        love.graphics.print(text, x + 1, y)
        love.graphics.print(text, x - 1, y)
        love.graphics.print(text, x, y + 1)
        love.graphics.print(text, x, y - 1)
        -- draw color:
        love.graphics.setColor(style.r, style.g, style.b)
        love.graphics.print(text, x, y)
        -- concatenate prefix:
        prefix = prefix .. '\n'
    love.graphics.pop()
    end
    -- reset color: love.graphics.pop() only resets transformations
    love.graphics.setColor(1, 1, 1)
end


---@param a vec2
---@param b vec2
---@param t number
---@return vec2
function lerp_vec2(a, b, t)
    local x = Mathx.lerp(a.x, b.x, t)
    local y = Mathx.lerp(a.y, b.y, t)
    return vec2(x, y)
end