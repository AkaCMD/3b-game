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
	CursorEffects.update_state(self.visual, self.pos.x, self.pos.y, dt, love.mouse.isDown(1))
end

function Cursor:draw()
	Entity.draw(self)

	local img = Assets.images.cursor
	local draw_x = self.visual.render_x + self.visual.offset_x
	local draw_y = self.visual.render_y + self.visual.offset_y
	local draw_scale_x = self.baseScale.x * self.visual.scale_x
	local draw_scale_y = self.baseScale.y * self.visual.scale_y

	love.graphics.draw(
		img,
		draw_x,
		draw_y,
		self.visual.rotation,
		draw_scale_x,
		draw_scale_y,
		img:getWidth()/2,
		img:getHeight()/2
	)
end
