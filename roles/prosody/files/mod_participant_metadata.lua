local _jid = require "util.jid";

log('info', 'Loaded Custom Presence identity');

module:hook("pre-presence/full", function (event)

  local function get_room_from_jid(jid)
    local node, host = _jid.split(jid);
    local component = hosts[host];
      
    if component then
      local muc = component.modules.muc
      if muc and rawget(muc,"rooms") then
        -- We're running 0.9.x or 0.10 (old MUC API)
        return muc.rooms[jid];
      elseif muc and rawget(muc,"get_room_from_jid") then
        -- We're running >0.10 (new MUC API)
        return muc.get_room_from_jid(jid);
      else
        return
      end
    end
  end

  local origin, stanza = event.origin, event.stanza;
  local to = _jid.bare(stanza.attr.to);

  if get_room_from_jid(to) then
    local room = get_room_from_jid(to);
    local occupant = room._occupants[tostring(stanza.attr.to)];

    if occupant then
      local email = stanza:get_child_text("email") or "";
      local role = tostring(occupant.role);

      if email ~= "" and role == "moderator" then
        stanza:maptags(
          function(tag)
            for k, v in pairs(tag) do
              if k == "name" and v == "identity" then
                return nil
              end
            end
          return tag
        end)

        stanza:tag("identity"):tag("user");
        stanza:tag("id"):text(email):up();
        stanza:up();
      end
    end
  end
end);
