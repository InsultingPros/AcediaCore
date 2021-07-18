class AvariceMessage extends AcediaObject;

var private Text messageID;
var private Text messageGroup;

var public AcediaObject data;

var private AssociativeArray messageTemplate;

public static function StaticConstructor()
{
    if (StaticConstructorGuard()) return;
    super.StaticConstructor();

    default.messageTemplate = __().collections.EmptyAssociativeArray();
    ResetTemplate(default.messageTemplate);
}

protected function Finalizer()
{
    __().memory.Free(messageID);
    __().memory.Free(messageGroup);
    __().memory.Free(data);
    messageID = none;
    messageGroup = none;
    data = none;
}

private static final function ResetTemplate(AssociativeArray template)
{
    if (template == none) {
        return;
    }
    template.SetItem(P("i"), none);
    template.SetItem(P("g"), none);
    template.SetItem(P("p"), none);
}

public final function SetID(Text id)
{
    _.memory.Free(messageID);
    messageID = none;
    if (id != none) {
        messageID = id.Copy();
    }
}

public final function Text GetID()
{
    if (messageID != none) {
        return messageID.Copy();
    }
    return none;
}

public final function SetGroup(Text group)
{
    _.memory.Free(messageGroup);
    messageGroup = none;
    if (group != none) {
        messageGroup = group.Copy();
    }
}

public final function Text GetGroup()
{
    if (messageGroup != none) {
        return messageGroup.Copy();
    }
    return none;
}

public final function MutableText ToText()
{
    local MutableText       result;
    local AssociativeArray  template;
    if (messageID == none)      return none;
    if (messageGroup == none)   return none;

    template = default.messageTemplate;
    template.SetItem(P("i"), messageID);
    template.SetItem(P("g"), messageGroup);
    if (data != none) {
        template.SetItem(P("p"), data);
    }
    result = _.json.Print(template);
    ResetTemplate(template);
    return result;
}

defaultproperties
{
}