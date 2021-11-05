# Databases
!!! Do not tell about recommended db type
!!! Tell about no intention to bother with access rights
While most mods' needs for storing data can be easily covered by config files, there are still use cases that require more powerful tools like databases:

* With config files alone it is impossible to share data between several different servers, especially if they are located on different machines;
* Representing hierarchical data in config files, while not impossible, can be quite tricky (and any generic implementation can itself be called a database).

Acedia provides it's own information storage functionality in form of databases that store information in JSON format. That is, every Acedia's database is represented by a JSON object, that can be interacted with by provided database API. Two implementations are provided:

1. **Remote database** *(not yet implemented)* that provides Acedia an ability to connect to Avarice database over TCP connection, allowing such database to be used by several servers at once;
2. **Local database** that store information in server's own directory, making it only accessible from that server. While using remote databases is recommended, local ones make sure that Acedia can function even if server admin does not want to use external software.

## Using databases

To demonstrate basic of working with Acedia's databases, let's consider a simple, practice problem: creating a feature that can remember shared text notes in the database and later display all the accumulated ones.

```unrealscript
class NoteTaker extends Feature;

var private Database    myDatabase;
var private JSONPointer realmPointer;

var private LoggerAPI.Definition errFailedToRead, errBadData, errHadBadNotes;

protected function Constructor()
{
    local DynamicArray emptyArray;
    myDatabase      = _.db.Realms();
    realmPointer    = _.db.RealmsPointer();
    realmPointer.Push(P("NoteTaker"));
    emptyArray = _.collections.EmptyDynamicArray();
    db.IncrementData(realmPointer, emptyArray);
    emptyArray.FreeSelf();
}

public function TakeNote(Text newNote)
{
    local DynamicArray wrapper;
    if (newNote == none) {
        return;
    }
    wrapper = _.collections
        .EmptyDynamicArray()
        .AddItem(newNote);
    db.IncrementData(realmPointer, wrapper);
    wrapper.FreeSelf();
}

public function PrintAllNotes()
{
    db.ReadData(realmPointer).connect = DoPrint;
}

private function DoPrint(DBQueryResult result, AcediaObject data)
{
    local int           i;
    local bool          hadBadNotes;
    local Text          nextNote;
    local DynamicArray  loadedArray;
    if (result != DBR_Success)
    {
        _.logger.Auto(errFailedToRead);
        _.memory.Free(data);
        return;
    }
    loadedArray = DynamicArray(data);
    if (loadedArray == none)
    {
        _.logger.Auto(errBadData);
        _.memory.Free(data);
        return;
    }
    for (i = 0; i < loadedArray.GetLength(); i += 1)
    {
        nextNote = loadedArray.GetText(i);
        if (nextNote != none) {
            Log("Note" @ (i+1) $ "." @ loadedArray.GetText(i).ToString());
        }
        else {
            hadBadNotes = true;
        }
    }
    if (hadBadNotes) {
        _.logger.Auto(errHadBadNotes);
    }
    _.memory.Free(data);
}

defaultproperties
{
    errFailedToRead = (l=LOG_Error,m="Could not read notes data from the database!")
    errBadData      = (l=LOG_Error,m="Notes database contained invalid data!")
    errHadBadNotes  = (l=LOG_Error,m="Some of the notes had wrong data format!")
}
```

....
Acedia assumes that *creating* and *deleting* databases is server admins's responsibility, since they have to make a choice of what type of database to use. So unless you are making a feature that is supposed to manage databases, **you should attempt to create or delete databases**. You need, instead, load already existing one via one of the several ways. Easiest way is using *realms*:

```unrealscript
local Database      db;
local JSONPointer   ptr;
db = _.db.Realm(P("MyMod")).database;
ptr = _.db.Realm(P("MyMod")).pointer;
```

### Issues: database might already contain badly formatted data - check it

### Improvements: delete notes

### Improvements: loading only one note

## Further topics
