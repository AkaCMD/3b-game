local CursorEffects = require("src.cursor_effects")

Cursor = class({
	name = "Cursor",
	extends = Entity,
	default_tostring = true
})

function Cursor:new(pos, scale)
	self:super(pos, scale)
	self.lastPos = self.pos
	self.baseScale = self.scale:copy()
	self.visual = CursorEffects.new_state(self.pos.x, self.pos.y)
	self.hasCollision = false
    self:set_tag("cursor")
end

function Cursor:update(dt, context)
	self.lastPos = self.pos
	Entity.update(self, dt, context)
	self.pos = vec2(love.mouse.getX(), love.mouse.getY())
	CursorEffects.update_state(self.visual, self.pos.x, self.pos.y, dt)
end

function Cursor:draw()
	Entity.draw(self)

	local img = Assets.images.cursor
	love.graphics.draw(
		img,
		self.pos.x,
		self.pos.y,
		self.visual.rotation,
		self.baseScale.x,
		self.baseScale.y,
		img:getWidth()/2,
		img:getHeight()/2
	)
end
