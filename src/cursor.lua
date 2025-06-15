Cursor = class({
	name = "Cursor",
	extends = Entity,
	default_tostring = true
})

function Cursor:new(pos, scale)
	self:super(pos, scale)
	self.lastPos = self.pos
	self.hasCollision = false
end

function Cursor:update(dt)
	self.lastPos = self.pos
	Entity:update(dt)
	self.pos = vec2(love.mouse.getX(), love.mouse.getY())
end

function Cursor:draw()
	Entity:draw()

	local img = assets.images.cursor
	if self.lastPos.x > self.pos.x then
		love.graphics.draw(img, self.pos.x, self.pos.y, math.rad(-10), self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	elseif self.lastPos.x < self.pos.x then
		love.graphics.draw(img, self.pos.x, self.pos.y, math.rad(10), self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	else
		love.graphics.draw(img, self.pos.x, self.pos.y, 0, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	end
end