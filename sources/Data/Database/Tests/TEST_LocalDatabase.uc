/**
 *  Set of tests for `DBRecord` class.
 *      Copyright 2021-2022 Anton Tarasenko
 *------------------------------------------------------------------------------
 * This file is part of Acedia.
 *
 * Acedia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License, or
 * (at your option) any later version.
 *
 * Acedia is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Acedia.  If not, see <https://www.gnu.org/licenses/>.
 */
class TEST_LocalDatabase extends TestCase
    abstract;

//  Results of callback are written here
var protected int                       resultSize;
var protected ArrayList                 resultKeys;
var protected Database.DBQueryResult    resultType;
var protected Database.DataType         resultDataType;
var protected HashTable                 resultData;
var protected AcediaObject              resultObject;

protected function DBReadingHandler(
    Database.DBQueryResult  result,
    AcediaObject            data,
    Database                source)
{
    default.resultType      = result;
    default.resultObject    = data;
    default.resultData      = HashTable(data);
}

protected function DBKeysHandler(
    Database.DBQueryResult  result,
    ArrayList               keys,
    Database                source)
{
    default.resultType = result;
    default.resultKeys = keys;
}

protected function DBCheckHandler(
    Database.DBQueryResult  result,
    Database.DataType       type,
    Database                source)
{
    default.resultType = result;
    default.resultDataType = type;
}

protected function DBSizeHandler(
    Database.DBQueryResult  result,
    int                     size,
    Database                source)
{
    default.resultType = result;
    default.resultSize = size;
}

protected function DBWritingHandler(
    Database.DBQueryResult  result,
    Database                source)
{
    default.resultType = result;
}

protected function DBIncrementHandler(
    Database.DBQueryResult  result,
    Database                source)
{
    default.resultType = result;
}

protected function DBRemoveHandler(
    Database.DBQueryResult  result,
    Database                source)
{
    default.resultType = result;
}

protected static function ReadFromDB(LocalDatabaseInstance db, string pointer)
{
    local DBReadTask task;
    task = db.ReadData(__().json.Pointer(P(pointer)));
    task.connect = DBReadingHandler;
    task.TryCompleting();
}

protected static function int CountRecordsInPackage(string package)
{
    local int       counter;
    local DBRecord  nextRecord;
    local GameInfo  game;
    game = __server().unreal.GetGameType();
    foreach game.AllDataObjects(class'DBRecord', nextRecord, package) {
        counter += 1;
    }
    return counter;
}

/* JSON data written in the "MockLocalDBReadOnly" local database.
This is the code that has been used to create the "TEST_ReadOnly" package that
contains it:

local string                source;
local Parser                parser;
local HashTable             root;
local LocalDatabaseInstance db;
source = GetJSONTemplateString();
parser = __().text.ParseString(source);
root = HashTable(__().json.ParseWith(parser));
db = __().db.NewLocal(P("TEST_ReadOnly"));
db.WriteData(__().json.Pointer(), root);
*/
protected static function string GetJSONTemplateString()
{
    return  "{\"web-app\": {"
        @   "  \"servlet\": [   "
        @   "    {"
        @   "      \"servlet-name\": \"cofaxCDS\","
        @   "      \"servlet-class\": \"org.cofax.cds.CDSServlet\","
        @   "      \"init-param\": {"
        @   "        \"configGlossary:installationAt\": \"Philadelphia, PA\","
        @   "        \"configGlossary:adminEmail\": \"ksm@pobox.com\","
        @   "        \"configGlossary:poweredBy\": \"Cofax\","
        @   "        \"configGlossary:poweredByIcon\": \"/images/cofax.gif\","
        @   "        \"configGlossary:staticPath\": \"/content/static\","
        @   "        \"templateProcessorClass\": \"org.cofax.WysiwygTemplate\","
        @   "        \"templateLoaderClass\": \"org.cofax.FilesTemplateLoader\","
        @   "        \"templatePath\": \"templates\","
        @   "        \"templateOverridePath\": \"\","
        @   "        \"defaultListTemplate\": \"listTemplate.htm\","
        @   "        \"defaultFileTemplate\": \"articleTemplate.htm\","
        @   "        \"useJSP\": false,"
        @   "        \"jspListTemplate\": \"listTemplate.jsp\","
        @   "        \"jspFileTemplate\": \"articleTemplate.jsp\","
        @   "        \"cachePackageTagsTrack\": 200,"
        @   "        \"cachePackageTagsStore\": 200,"
        @   "        \"cachePackageTagsRefresh\": 60,"
        @   "        \"cacheTemplatesTrack\": 100,"
        @   "        \"cacheTemplatesStore\": 50,"
        @   "        \"cacheTemplatesRefresh\": 15,"
        @   "        \"cachePagesTrack\": 200,"
        @   "        \"cachePagesStore\": 100,"
        @   "        \"cachePagesRefresh\": 10,"
        @   "        \"cachePagesDirtyRead\": 10,"
        @   "        \"searchEngineListTemplate\": \"forSearchEnginesList.htm\","
        @   "        \"searchEngineFileTemplate\": \"forSearchEngines.htm\","
        @   "        \"searchEngineRobotsDb\": \"WEB-INF/robots.db\","
        @   "        \"useDataStore\": true,"
        @   "        \"dataStoreClass\": \"org.cofax.SqlDataStore\","
        @   "        \"redirectionClass\": \"org.cofax.SqlRedirection\","
        @   "        \"dataStoreName\": \"cofax\","
        @   "        \"dataStoreDriver\": \"com.microsoft.jdbc.sqlserver.SQLServerDriver\","
        @   "        \"dataStoreUrl\": \"jdbc:microsoft:sqlserver://LOCALHOST:1433;DatabaseName=goon\","
        @   "        \"dataStoreUser\": \"sa\","
        @   "        \"dataStorePassword\": \"dataStoreTestQuery\","
        @   "        \"dataStoreTestQuery\": \"SET NOCOUNT ON;select test='test';\","
        @   "        \"dataStoreLogFile\": \"/usr/local/tomcat/logs/datastore.log\","
        @   "        \"dataStoreInitConns\": 10,"
        @   "        \"dataStoreMaxConns\": 100,"
        @   "        \"dataStoreConnUsageLimit\": 100,"
        @   "        \"dataStoreLogLevel\": \"debug\","
        @   "        \"maxUrlLength\": 500}},"
        @   "    {"
        @   "      \"servlet-name\": \"cofaxEmail\","
        @   "      \"servlet-class\": \"org.cofax.cds.EmailServlet\","
        @   "      \"init-param\": {"
        @   "      \"mailHost\": \"mail1\","
        @   "      \"mailHostOverride\": \"mail2\"}},"
        @   "    {"
        @   "      \"servlet-name\": \"cofaxAdmin\","
        @   "      \"servlet-class\": \"org.cofax.cds.AdminServlet\"},"
        @   " "
        @   "    {"
        @   "      \"servlet-name\": \"fileServlet\","
        @   "      \"servlet-class\": \"org.cofax.cds.FileServlet\"},"
        @   "    {"
        @   "      \"servlet-name\": \"cofaxTools\","
        @   "      \"servlet-class\": \"org.cofax.cms.CofaxToolsServlet\","
        @   "      \"init-param\": {"
        @   "        \"templatePath\": \"toolstemplates/\","
        @   "        \"log\": 1,"
        @   "        \"logLocation\": \"/usr/local/tomcat/logs/CofaxTools.log\","
        @   "        \"logMaxSize\": \"\","
        @   "        \"dataLog\": 1,"
        @   "        \"dataLogLocation\": \"/usr/local/tomcat/logs/dataLog.log\","
        @   "        \"dataLogMaxSize\": \"\","
        @   "        \"removePageCache\": \"/content/admin/remove?cache=pages&id=\","
        @   "        \"removeTemplateCache\": \"/content/admin/remove?cache=templates&id=\","
        @   "        \"fileTransferFolder\": \"/usr/local/tomcat/webapps/content/fileTransferFolder\","
        @   "        \"lookInContext\": 1,"
        @   "        \"adminGroupID\": 4,"
        @   "        \"betaServer\": true}}],"
        @   "  \"servlet-mapping\": {"
        @   "    \"cofaxCDS\": \"/\","
        @   "    \"cofaxEmail\": \"/cofaxutil/aemail/*\","
        @   "    \"cofaxAdmin\": \"/admin/*\","
        @   "    \"fileServlet\": \"/static/*\","
        @   "    \"cofaxTools\": \"/tools/*\"},"
        @   " "
        @   "  \"taglib\": {"
        @   "    \"taglib-uri\": \"cofax.tld\","
        @   "    \"taglib-location\": \"/WEB-INF/tlds/cofax.tld\"}}}";
}

protected static function TESTS()
{
    Test_LoadingPrepared();
    Test_Writing();
    Test_Recreate();
    Test_TaskChaining();
    Test_Removal();
    Test_Increment();
}

protected static function Test_LoadingPrepared()
{
    local LocalDatabaseInstance db;
    db = __().db.LoadLocal(P("TEST_ReadOnly"));
    Context("Testing reading prepared data from the local database.");
    Issue("Existing database reported as missing.");
    TEST_ExpectTrue(__().db.ExistsLocal(P("TEST_ReadOnly")));

    Issue("Loading same database several times produces different"
        @ "`LocalDatabaseInstance` objects.");
    TEST_ExpectTrue(__().db.LoadLocal(P("TEST_ReadOnly")) ==  db);
    //  Groups of read-only tests
    SubTest_LoadingPreparedSuccessRoot(db);
    SubTest_LoadingPreparedSuccessSubValues(db);
    SubTest_LoadingPreparedFailure(db);
    SubTest_LoadingPreparedCheckTypesSuccess(db);
    SubTest_LoadingPreparedCheckTypesFail(db);
    SubTest_LoadingPreparedGetSizePositive(db);
    SubTest_LoadingPreparedGetSizeNegative(db);
    SubTest_LoadingPreparedGetKeysSuccess(db);
    SubTest_LoadingPreparedGetKeysFail(db);
    __().memory.Free(db);
    __().memory.Free(db);
}

protected static function SubTest_LoadingPreparedSuccessRoot(
    LocalDatabaseInstance db)
{
    Issue("Data is being read incorrectly.");
    ReadFromDB(db, "");
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultData.GetLength() == 1);
    TEST_ExpectTrue(default.resultData
        .GetHashTableBy(P("/web-app")).GetLength() == 3);
    TEST_ExpectTrue(default.resultData
        .GetArrayListBy(P("/web-app/servlet")).GetLength() == 5);
    TEST_ExpectTrue(default.resultData
        .GetHashTableBy(P("/web-app/servlet/0/init-param"))
        .GetLength() == 42);
    TEST_ExpectTrue(default.resultData
        .GetTextBy(P("/web-app/servlet/2/servlet-class"))
        .ToString() == "org.cofax.cds.AdminServlet");
    TEST_ExpectFalse(default.resultData
        .GetBoolBy(P("/web-app/servlet/0/init-param/useJSP")));
    TEST_ExpectTrue(default.resultData
        .GetIntBy(P("/web-app/servlet/0/init-param/dataStoreMaxConns"))
        == 100);
}

protected static function SubTest_LoadingPreparedSuccessSubValues(
    LocalDatabaseInstance db)
{
    Issue("Sub-objects are being read incorrectly.");
    ReadFromDB(db, "/web-app/servlet-mapping");
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultData.GetLength() == 5);
    TEST_ExpectTrue(
        default.resultData.GetText(P("cofaxCDS")).ToString() == "/");
    TEST_ExpectTrue(
            default.resultData.GetText(P("cofaxEmail")).ToString()
        ==  "/cofaxutil/aemail/*");
    TEST_ExpectTrue(
            default.resultData.GetText(P("cofaxAdmin")).ToString()
        ==  "/admin/*");

    Issue("Simple values are being read incorrectly.");
    ReadFromDB(db, "/web-app/servlet/3/servlet-class");
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(
            Text(default.resultObject).ToString()
        ==  "org.cofax.cds.FileServlet");
    ReadFromDB(db, "/web-app/servlet/4/init-param/adminGroupID");
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(IntBox(default.resultObject).Get() == 4);
}

protected static function SubTest_LoadingPreparedFailure(
    LocalDatabaseInstance db)
{
    local DBReadTask task;
    Issue("Reading database values from incorrect path does not produce"
        @ "`DBR_InvalidPointer` result.");
    task = db.ReadData(none);
    task.connect = DBReadingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);
    ReadFromDB(db, "/web-app/servlet-mappings");
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);
    ReadFromDB(db, "/web-app/servlet/5");
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);
}

protected static function SubTest_LoadingPreparedCheckTypesSuccess(
    LocalDatabaseInstance db)
{
    local DBCheckTask task;
    Issue("`CheckDataType()` returns incorrect type for existing elements.");
    task = db.CheckDataType(__().json.Pointer(P("/web-app/servlet-mapping")));
    task.connect = DBCheckHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultDataType == JSON_Object);
    task = db.CheckDataType(__().json.Pointer(P("/web-app/taglib/taglib-uri")));
    task.connect = DBCheckHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultDataType == JSON_String);
    task = db.CheckDataType(__().json.Pointer(
        P("/web-app/servlet/0/init-param/cacheTemplatesRefresh")));
    task.connect = DBCheckHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultDataType == JSON_Number);
    task = db.CheckDataType(__().json.Pointer(
        P("/web-app/servlet/0/init-param/useJSP")));
    task.connect = DBCheckHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultDataType == JSON_Boolean);
}

protected static function SubTest_LoadingPreparedCheckTypesFail(
    LocalDatabaseInstance db)
{
    local DBCheckTask task;
    Issue("`CheckDataType()` returns incorrect type for missing elements.");
    task = db.CheckDataType(__().json.Pointer(P("/web-app/NothingHere")));
    task.connect = DBCheckHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultDataType == JSON_Undefined);

    Issue("`CheckDataType()` reports success for `none` pointer.");
    task = db.CheckDataType(none);
    task.connect = DBCheckHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);
}

protected static function SubTest_LoadingPreparedGetSizePositive(
    LocalDatabaseInstance db)
{
    local DBSizeTask task;
    Issue("Local database incorrectly reports size of arrays.");
    task = db.GetDataSize(__().json.Pointer(P("/web-app/servlet")));
    task.connect = DBSizeHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultSize == 5);

    Issue("Local database incorrectly reports size of objects.");
    task = db.GetDataSize(
        __().json.Pointer(P("/web-app/servlet/0/init-param")));
    task.connect = DBSizeHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultSize == 42);
}

protected static function SubTest_LoadingPreparedGetSizeNegative(
    LocalDatabaseInstance db)
{
    local DBSizeTask task;
    Issue("Local database does not report negative size value for"
        @ "non-array/object size.");
    task = db.GetDataSize(__().json.Pointer(P("/web-app/taglib/taglib-uri")));
    task.connect = DBSizeHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultSize < 0);

    Issue("Local database does not report negative size value for non-existing"
        @ "values.");
    task = db.GetDataSize(__().json.Pointer(P("/web-app/whoops")));
    task.connect = DBSizeHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultSize < 0);

    Issue("Local database does not report failure for empty pointer.");
    task = db.GetDataSize(__().json.Pointer(P("/web-app/whoops")));
    task.connect = DBSizeHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultSize < 0);
}

protected static function SubTest_LoadingPreparedGetKeysSuccess(
    LocalDatabaseInstance db)
{
    local int               i;
    local bool              rCDS, rEmail, rAdmin, rServlet, rTools;
    local string            nextKey;
    local DBKeysTask   task;
    Issue("Object keys are read incorrectly.");
    task = db.GetDataKeys(__().json.Pointer(P("/web-app/servlet-mapping")));
    task.connect = DBKeysHandler;
    task.TryCompleting();
    for (i = 0; i < default.resultKeys.GetLength(); i += 1)
    {
        nextKey = default.resultKeys.GetText(i).ToString();
        if (nextKey == "cofaxCDS")      rCDS = true;
        if (nextKey == "cofaxEmail")    rEmail = true;
        if (nextKey == "cofaxAdmin")    rAdmin = true;
        if (nextKey == "fileServlet")   rServlet = true;
        if (nextKey == "cofaxTools")    rTools = true;
    }
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultKeys.GetLength() == 5);
    TEST_ExpectTrue(rCDS && rEmail && rAdmin && rServlet && rTools);
}

protected static function SubTest_LoadingPreparedGetKeysFail(
    LocalDatabaseInstance db)
{
    local DBKeysTask task;
    Issue("Non-objects do not correctly cause failure for getting their"
        @ "key arrays.");
    task = db.GetDataKeys(__().json.Pointer(P("/web-app/servlet")));
    task.connect = DBKeysHandler;
    task.TryCompleting();
    TEST_ExpectNone(default.resultKeys);
    task = db.GetDataKeys(
        __().json.Pointer(P("/web-app/servlet/1/mailHostOverride")));
    task.connect = DBKeysHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidData);
    TEST_ExpectNone(default.resultKeys);

    Issue("Missing values do not correctly cause failure for getting their"
        @ "key arrays.");
    task = db.GetDataKeys(__().json.Pointer(P("/web-app/a-what-now?")));
    task.connect = DBKeysHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidData);
    TEST_ExpectNone(default.resultKeys);

    Issue("Obtaining key arrays for `none` JSON pointers does not"
        @ "produce errors.");
    task = db.GetDataKeys(none);
    task.connect = DBKeysHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);
    TEST_ExpectNone(default.resultKeys);
}

protected static function Test_Writing()
{
    local LocalDatabaseInstance db;
    db = __().db.NewLocal(P("TEST_DB"));
    Context("Testing (re-)creating and writing into a new local database.");
    Issue("Cannot create a new database.");
    TEST_ExpectNotNone(db);
    TEST_ExpectTrue(__().db.ExistsLocal(P("TEST_DB")));

    Issue("Freshly created database is not empty.");
    TEST_ExpectTrue(CountRecordsInPackage("TEST_DB") == 1); //  1 root object

    Issue("Loading just created database produces different"
        @ "`LocalDatabaseInstance` object.");
    TEST_ExpectTrue(__().db.LoadLocal(P("TEST_DB")) == db);
    //  This set of tests fills our test database with objects
    SubTest_WritingSuccess(db);
    SubTest_WritingDataCheck(db);
    SubTest_WritingDataCheck_Immutable(db);
    SubTest_WritingDataCheck_Mutable(db);
    SubTest_WritingFailure(db);
    SubTest_WritingIntoSimpleValues(db);

    Issue("`DeleteLocal()` does not return `true` after deleting existing"
        @ "local database.");
    __().memory.Free(db);   //  For `NewLocal()` call
    __().memory.Free(db);   //  For `LoadLocal()` call
    TEST_ExpectTrue(__().db.DeleteLocal(P("TEST_DB")));

    Issue("Newly created database is reported to still exist after deletion.");
    TEST_ExpectFalse(__().db.ExistsLocal(P("TEST_DB")));
    TEST_ExpectFalse(db.IsAllocated());

    Issue("`DeleteLocal()` does not return `false` after trying to delete"
        @ "non-existing local database.");
    TEST_ExpectFalse(__().db.DeleteLocal(P("TEST_DB")));
}

protected static function Test_Recreate()
{
    local LocalDatabaseInstance db;
    Issue("Freshly created database is not empty.");
    db = __().db.NewLocal(P("TEST_DB"));
    TEST_ExpectTrue(CountRecordsInPackage("TEST_DB") == 1);

    Issue("Cannot create a database after database with the same name was"
        @ "just deleted.");
    TEST_ExpectNotNone(db);
    TEST_ExpectTrue(__().db.ExistsLocal(P("TEST_DB")));
    SubTest_WritingArrayIndicies(db);
    __().db.DeleteLocal(P("TEST_DB"));
    Issue("Newly created database is reported to still exist after deletion.");
    __().memory.Free(db);
    TEST_ExpectFalse(__().db.ExistsLocal(P("TEST_DB")));
    TEST_ExpectFalse(db.IsAllocated());
}

protected static function Test_TaskChaining()
{
    local LocalDatabaseInstance db;
    Context("Testing (re-)creating and writing into a new local database.");
    Issue("Freshly created database is not empty.");
    db = __().db.NewLocal(P("TEST_DB"));
    TEST_ExpectTrue(CountRecordsInPackage("TEST_DB") == 1);

    Issue("Cannot create a database after database with the same name was"
        @ "just deleted.");
    TEST_ExpectNotNone(db);
    TEST_ExpectTrue(__().db.ExistsLocal(P("TEST_DB")));
    SubTest_TaskChaining(db);
    __().db.DeleteLocal(P("TEST_DB"));
}

protected static function HashTable GetJSONSubTemplateObject()
{
    local Parser parser;
    parser = __().text.ParseString("{\"A\":\"simpleValue\",\"B\":11.12}");
    return HashTable(__().json.ParseWith(parser));
}

protected static function ArrayList GetJSONSubTemplateArray()
{
    local Parser parser;
    parser = __().text.ParseString("[true, null, \"huh\"]");
    return ArrayList(__().json.ParseWith(parser));
}

/*
In the following function we construct the following JSON object inside
the database by using templates provided by `GetJSONSubTemplateObject()` and
`GetJSONSubTemplateArray()`:
{
    "A": "simpleValue",
    "B": {
        "A": [true, {
            "A": "simpleValue",
            "B": 11.12,
            "": [true, null, "huh"]
        }, "huh"],
        "B": 11.12
    }
}
*/
protected static function SubTest_WritingSuccess(LocalDatabaseInstance db)
{
    local DBWriteTask   task;
    local ArrayList     templateArray;
    local HashTable     templateObject;
    templateObject = GetJSONSubTemplateObject();
    templateArray = GetJSONSubTemplateArray();
    Issue("`WriteData()` call that is supposed to succeed reports failure.");
    task = db.WriteData(__().json.Pointer(P("")), templateObject);
    task.connect = DBWritingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    task = db.WriteData(__().json.Pointer(P("/B")), templateObject);
    task.connect = DBWritingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    task = db.WriteData(__().json.Pointer(P("/B/A")), templateArray);
    task.connect = DBWritingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    //  Rewrite object to test whether it will create trash
    db.WriteData(__().json.Pointer(P("/B/A/1")), templateObject).TryCompleting();
    db.WriteData(__().json.Pointer(P("/B/A/1")), templateArray).TryCompleting();
    task = db.WriteData(__().json.Pointer(P("/B/A/1")), templateObject);
    task.connect = DBWritingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    task = db.WriteData(__().json.Pointer(P("/B/A/1/")), templateArray);
    task.connect = DBWritingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    Issue("`WriteData()` creates garbage objects inside database's package.");
    TEST_ExpectTrue(CountRecordsInPackage("TEST_DB") == 5);
}

protected static function SubTest_WritingDataCheck(LocalDatabaseInstance db)
{
    Issue("Created database does not load expected values as"
        @ "immutable types with `makeMutable` parameter set to `false`.");
    //  Full db read
    ReadFromDB(db, "");
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultData.GetLength() == 2);
    TEST_ExpectTrue(
            default.resultData.GetTextBy(P("/B/A/1//2")).ToString()
        ==  "huh");
    TEST_ExpectTrue(
            default.resultData.GetTextBy(P("/A")).ToString()
        ==  "simpleValue");
    TEST_ExpectTrue(default.resultData.GetFloatBy(P("/B/B")) == 11.12);
    TEST_ExpectTrue(default.resultData.GetBoolBy(P("/B/A/0"), false));
    TEST_ExpectNone(default.resultData.GetItemBy(P("/B/A/1//1")));
}

protected static function SubTest_WritingDataCheck_Immutable(
    LocalDatabaseInstance db)
{
    Issue("Created database does not load expected values as"
        @ "mutable types with `makeMutable` parameter set to `true`.");
    //  Full db read
    ReadFromDB(db, "");
    TEST_ExpectTrue(
            default.resultData.GetItemBy(P("/B/A/1//2")).class
        ==  class'Text');
    TEST_ExpectTrue(
            default.resultData.GetItemBy(P("/A")).class
        ==  class'Text');
    TEST_ExpectTrue(
            default.resultData.GetItemBy(P("/B/B")).class
        ==  class'FloatBox');
    TEST_ExpectTrue(
            default.resultData.GetItemBy(P("/B/A/0")).class
        ==  class'BoolBox');
}

protected static function SubTest_WritingDataCheck_Mutable(
    LocalDatabaseInstance db)
{
    local DBReadTask task;
    Issue("Created database does not contain expected values.");
    //  Full db read
    task = db.ReadData(__().json.Pointer(P("")), true);
    task.connect = DBReadingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(
            default.resultData.GetItemBy(P("/B/A/1//2")).class
        ==  class'MutableText');
    TEST_ExpectTrue(
            default.resultData.GetItemBy(P("/A")).class
        ==  class'MutableText');
    TEST_ExpectTrue(
            default.resultData.GetItemBy(P("/B/B")).class
        ==  class'FloatRef');
    TEST_ExpectTrue(
            default.resultData.GetItemBy(P("/B/A/0")).class
        ==  class'BoolRef');
}

protected static function SubTest_WritingFailure(LocalDatabaseInstance db)
{
    local DBWriteTask   task;
    local ArrayList     templateArray;
    local HashTable     templateObject;
    templateObject = GetJSONSubTemplateObject();
    templateArray = GetJSONSubTemplateArray();
    Issue("`WriteData()` does not report error when attempting writing data at"
        @ "impossible path.");
    task = db.WriteData(__().json.Pointer(P("/A/B/C/D")), templateObject);
    task.connect = DBWritingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);

    Issue("`WriteData()` does not report error when attempting to write"
        @ "JSON array as the root value.");
    task = db.WriteData(__().json.Pointer(P("")), templateArray);
    task.connect = DBWritingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidData);

    Issue("`WriteData()` does not report error when attempting to write"
        @ "simple JSON value as the root value.");
    task = db.WriteData(__().json.Pointer(P("")), __().box.int(14641));
    task.connect = DBWritingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidData);
}

protected static function SubTest_WritingIntoSimpleValues(
    LocalDatabaseInstance db)
{
    local DBWriteTask task;
    //  This test is rather specific, but it was added because of the bug
    Issue("Writing sub-value inside a simple value will cause operation to"
        @ "report success and write new value into simple one's parent"
        @ "structure.");
    task = db.WriteData(__().json.Pointer(P("/B/B/new")), __().box.int(7));
    task.connect = DBWritingHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);
    ReadFromDB(db, "/B/new");
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);
    TEST_ExpectNone(default.resultObject);
}

protected static function SubTest_WritingArrayIndicies(LocalDatabaseInstance db)
{
    local DBWriteTask   writeTask;
    local ArrayList     resultArray;
    local ArrayList     templateArray;
    local HashTable     templateObject;
    templateObject = GetJSONSubTemplateObject();
    templateArray = GetJSONSubTemplateArray();
    db.WriteData(__().json.Pointer(P("")), templateObject);
    db.WriteData(__().json.Pointer(P("/A")), templateArray);
    db.WriteData(__().json.Pointer(P("/A/100")), __().box.int(-342));
    db.WriteData(__().json.Pointer(P("/A/-")), __().box.int(95));

    Issue("Database allows writing data into negative JSON array indices.");
    writeTask = db.WriteData(__().json.Pointer(P("/A/-5")), __().box.int(1202));
    writeTask.connect = DBWritingHandler;
    writeTask.TryCompleting();

    Issue("Database cannot extend stored JSON array's length by assigning to"
        @ "the out-of-bounds index or \"-\".");
    ReadFromDB(db, "/A");
    resultArray = ArrayList(default.resultObject);
    TEST_ExpectTrue(resultArray.GetLength() == 102);
    TEST_ExpectNone(resultArray.GetItem(99));
    TEST_ExpectTrue(resultArray.GetInt(100) == -342);
    TEST_ExpectTrue(resultArray.GetInt(101) == 95);
    TEST_ExpectTrue(resultArray.GetBool(0));
}

protected static function SubTest_TaskChaining(LocalDatabaseInstance db)
{
    local DBWriteTask   writeTask;
    local ArrayList     templateArray;
    local HashTable     templateObject;
    templateObject = GetJSONSubTemplateObject();
    templateArray = GetJSONSubTemplateArray();
    db.WriteData(__().json.Pointer(P("")), templateObject);
    db.WriteData(__().json.Pointer(P("/B")), templateArray);
    db.ReadData(__().json.Pointer(P("/B/2"))).connect
        = DBReadingHandler;
    writeTask = db.WriteData(__().json.Pointer(P("/B/2")), templateArray);
    writeTask.TryCompleting();

    Issue("Chaining several tasks for the database leads to a failure.");
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultObject.class == class'Text');
    TEST_ExpectTrue(Text(default.resultObject).ToString() == "huh");
    ReadFromDB(db, "/B/2");
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultObject.class == class'ArrayList');
    TEST_ExpectTrue(ArrayList(default.resultObject).GetLength() == 3);
    TEST_ExpectTrue(ArrayList(default.resultObject).GetBool(0)   );
}

protected static function Test_Removal()
{
    local LocalDatabaseInstance db;
    local ArrayList             templateArray;
    local HashTable             templateObject;
    templateObject = GetJSONSubTemplateObject();
    templateArray = GetJSONSubTemplateArray();
    db = __().db.NewLocal(P("TEST_DB"));
    db.WriteData(__().json.Pointer(P("")), templateObject);
    db.WriteData(__().json.Pointer(P("/B")), templateObject);
    db.WriteData(__().json.Pointer(P("/B/A")), templateArray);
    db.WriteData(__().json.Pointer(P("/B/A/1")), templateObject);
    db.WriteData(__().json.Pointer(P("/B/A/1/")), templateArray);

    Context("Testing removing data from local database.");
    SubTest_RemovalResult(db);
    SubTest_RemovalCheckValuesAfter(db);
    SubTest_RemovalRoot(db);
    __().db.DeleteLocal(P("TEST_DB"));
}

protected static function SubTest_RemovalResult(LocalDatabaseInstance db)
{
    local DBRemoveTask removeTask;
    Issue("Removing data does not correctly fail when attempting to remove"
        @ "non-existing objects.");
    removeTask = db.RemoveData(__().json.Pointer(P("/C")));
    removeTask.connect = DBRemoveHandler;
    removeTask.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);
    removeTask = db.RemoveData(__().json.Pointer(P("/B/A/1//")));
    removeTask.connect = DBRemoveHandler;
    removeTask.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidPointer);

    Issue("Removing data does not succeed when it is expected to.");
    removeTask = db.RemoveData(__().json.Pointer(P("/B/B")));
    removeTask.connect = DBRemoveHandler;
    removeTask.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    removeTask = db.RemoveData(__().json.Pointer(P("/B/A/1")));
    removeTask.connect = DBRemoveHandler;
    removeTask.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
}

protected static function SubTest_RemovalCheckValuesAfter(
    LocalDatabaseInstance db)
{
    /* Expected data: {
        "A": "simpleValue",
        "B": {
            "A": [true, "huh"]
        }
    }
    */
    Issue("`DeleteData()` leaves garbage objects behind.");
    TEST_ExpectTrue(CountRecordsInPackage("TEST_DB") == 3);

    Issue("Database values do not look like expected after data removal.");
    ReadFromDB(db, "/B");
    TEST_ExpectTrue(default.resultData.GetLength() == 1);
    TEST_ExpectTrue(default.resultData.HasKey(P("A")));
    TEST_ExpectTrue(
        default.resultData.GetArrayList(P("A")).GetLength() == 2);
    TEST_ExpectTrue(default.resultData.GetArrayList(P("A")).GetBool(0));
    TEST_ExpectTrue(default.resultData.GetArrayList(P("A"))
            .GetText(1).ToString()
        ==  "huh");
}

protected static function SubTest_RemovalRoot(LocalDatabaseInstance db)
{
    local DBRemoveTask removeTask;
    Issue("Removing root object from the database does not"
        @ "work as expected.");
    removeTask = db.RemoveData(__().json.Pointer(P("")));
    removeTask.connect = DBRemoveHandler;
    removeTask.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "");
    TEST_ExpectTrue(default.resultType == DBR_Success);
    TEST_ExpectTrue(default.resultData.GetLength() == 0);
}

protected static function Test_Increment()
{
    local LocalDatabaseInstance db;
    local ArrayList             templateArray;
    local HashTable             templateObject;
    templateObject = GetJSONSubTemplateObject();
    templateArray = GetJSONSubTemplateArray();
    db = __().db.NewLocal(P("TEST_DB"));
    db.WriteData(__().json.Pointer(P("")), templateObject);
    db.WriteData(__().json.Pointer(P("/B")), templateObject);
    db.WriteData(__().json.Pointer(P("/C")), __().box.int(-5));
    db.WriteData(__().json.Pointer(P("/D")), __().box.bool(false));
    db.WriteData(__().json.Pointer(P("/B/A")), templateArray);
    db.WriteData(__().json.Pointer(P("/B/A/1")), templateObject);
    db.WriteData(__().json.Pointer(P("/B/A/1/")), templateArray);
    /* `db` now contains:
    {
        "A": "simpleValue",
        "B": {
            "A": [true, {
                "A": "simpleValue",
                "B": 11.12,
                "": [true, null, "huh"]
            }, "huh"],
            "B": 11.12
        },
        "C": -5,
        "D": false
    }
    */
    //      Constantly recreating `db` takes time, so we make test dependent
    //  on each other.
    //      Generally speaking this is not great, but we cannot run them in
    //  parallel anyway.
    Context("Testing incrementing data inside local database.");
    SubTest_IncrementNull(db);
    SubTest_IncrementBool(db);
    SubTest_IncrementNumeric(db);
    SubTest_IncrementString(db);
    SubTest_IncrementObject(db);
    SubTest_IncrementArray(db);
    SubTest_IncrementRewriteBool(db, templateArray, templateObject);
    SubTest_IncrementRewriteNumeric(db, templateArray, templateObject);
    SubTest_IncrementRewriteString(db, templateArray, templateObject);
    SubTest_IncrementRewriteObject(db, templateArray, templateObject);
    SubTest_IncrementRewriteArray(db, templateArray, templateObject);
    SubTest_IncrementMissing(db);
    Issue("Incrementing database values has created garbage objects.");
    //  5 initial records + 1 made for a new array in `SubTest_IncrementNull()`
    TEST_ExpectTrue(CountRecordsInPackage("TEST_DB") == 6);
    __().db.DeleteLocal(P("TEST_DB"));
}

protected static function SubTest_IncrementNull(LocalDatabaseInstance db)
{
    local DBIncrementTask task;
    Issue("JSON null values are not incremented properly.");
    task = db.IncrementData(__().json.Pointer(P("/B/A/1//1")), none);
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/B/A/1/");
    TEST_ExpectTrue(ArrayList(default.resultObject).GetLength() == 3);
    TEST_ExpectNone(ArrayList(default.resultObject).GetItem(1));
    task = db.IncrementData(
        __().json.Pointer(P("/B/A/1//1")), GetJSONSubTemplateArray());
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    task = db.IncrementData(
        __().json.Pointer(P("/B/A/1//1/1")), __().box.int(2));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/B/A/1/");
    TEST_ExpectTrue(default.resultObject.class == class'ArrayList');
    TEST_ExpectNotNone(ArrayList(default.resultObject).GetArrayList(1));
    TEST_ExpectTrue(
        ArrayList(default.resultObject).GetArrayList(1).GetInt(1) == 2);
}

protected static function SubTest_IncrementBool(LocalDatabaseInstance db)
{
    local DBIncrementTask task;
    Issue("JSON's boolean values are not incremented properly.");
    task = db.IncrementData(__().json.Pointer(P("/D")), __().box.bool(false));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/D");
    TEST_ExpectNotNone(BoolBox(default.resultObject));
    TEST_ExpectFalse(BoolBox(default.resultObject).Get());
    task = db.IncrementData(__().json.Pointer(P("/D")), __().box.bool(true));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/D");
    TEST_ExpectTrue(BoolBox(default.resultObject).Get());
    task = db.IncrementData(__().json.Pointer(P("/D")), __().box.bool(false));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/D");
    TEST_ExpectTrue(BoolBox(default.resultObject).Get());
}

protected static function SubTest_IncrementNumeric(LocalDatabaseInstance db)
{
    local DBIncrementTask task;
    Issue("JSON's numeric values are not incremented properly.");
    task = db.IncrementData(__().json.Pointer(P("/C")), __().box.int(10));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/C");
    TEST_ExpectTrue(IntBox(default.resultObject).Get() == 5);
    task = db.IncrementData(__().json.Pointer(P("/C")), __().box.float(0.5));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/C");
    TEST_ExpectTrue(FloatBox(default.resultObject).Get() == 5.5);
    task = db.IncrementData(__().json.Pointer(P("/B/B")), __().box.int(-1));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/B/B");
    TEST_ExpectTrue(FloatBox(default.resultObject).Get() == 10.12);
}

protected static function SubTest_IncrementString(LocalDatabaseInstance db)
{
    local DBIncrementTask task;
    Issue("JSON's string values are not incremented properly.");
    task = db.IncrementData(__().json.Pointer(P("/A")),
                            __().text.FromString(""));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/A");
    TEST_ExpectTrue(
        Text(default.resultObject).ToString() == "simpleValue");
    task = db.IncrementData(__().json.Pointer(P("/A")),
                            __().text.FromString("!"));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/A");
    TEST_ExpectTrue(
        Text(default.resultObject).ToString() == "simpleValue!");
    task = db.IncrementData(__().json.Pointer(P("/A")),
                            __().text.FromString("?"));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/A");
    TEST_ExpectTrue(
        Text(default.resultObject).ToString() == "simpleValue!?");
}

protected static function HashTable GetHelperObject()
{
    local HashTable result;
    result = __().collections.EmptyHashTable();
    result.SetItem(P("A"), __().text.FromString("complexString"));
    result.SetItem(P("E"), __().text.FromString("str"));
    result.SetItem(P("F"), __().ref.float(45));
    return result;
}

protected static function SubTest_IncrementObject(LocalDatabaseInstance db)
{
    local DBIncrementTask task;
    Issue("JSON objects are not incremented properly.");
    task = db.IncrementData(__().json.Pointer(P("")),
                            __().collections.EmptyHashTable());
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "");
    TEST_ExpectNotNone(default.resultData);
    TEST_ExpectTrue(default.resultData.GetLength() == 4);
    //  Check that value was not overwritten
    TEST_ExpectTrue(
        default.resultData.GetText(P("A")).ToString() == "simpleValue!?");
    task = db.IncrementData(__().json.Pointer(P("")),
                            GetHelperObject());
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "");
    TEST_ExpectNotNone(default.resultData);
    TEST_ExpectTrue(default.resultData.GetLength() == 6);
    TEST_ExpectTrue(
        default.resultData.GetText(P("E")).ToString() == "str");
    TEST_ExpectTrue(default.resultData.GetFloat(P("F")) == 45);
    TEST_ExpectTrue(
        default.resultData.GetItem(P("B")).class == class'HashTable');
    Issue("Incrementing JSON objects can overwrite existing data.");
    TEST_ExpectTrue(
        default.resultData.GetText(P("A")).ToString() == "simpleValue!?");
}

protected static function ArrayList GetHelperArray()
{
    local ArrayList result;
    result = __().collections.EmptyArrayList();
    result.AddItem(__().text.FromString("complexString"));
    result.AddItem(__().ref.float(45));
    result.AddItem(none);
    result.AddItem(__().ref.bool(true));
    return result;
}

protected static function SubTest_IncrementArray(LocalDatabaseInstance db)
{
    local DBIncrementTask task;
    Issue("JSON arrays are not incremented properly.");
    task = db.IncrementData(__().json.Pointer(P("/B/A")),
                            __().collections.EmptyArrayList());
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/B/A");
    TEST_ExpectTrue(ArrayList(default.resultObject).GetLength() == 3);
    TEST_ExpectTrue(
        ArrayList(default.resultObject).GetText(2).ToString() == "huh");
    task = db.IncrementData(__().json.Pointer(P("/B/A")),
                            GetHelperArray());
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    ReadFromDB(db, "/B/A");
    TEST_ExpectTrue(ArrayList(default.resultObject).GetLength() == 7);
    TEST_ExpectTrue(ArrayList(default.resultObject).GetBool(0));
    TEST_ExpectNotNone(
        ArrayList(default.resultObject).GetHashTable(1));
    TEST_ExpectTrue(
        ArrayList(default.resultObject).GetText(2).ToString() == "huh");
    TEST_ExpectTrue(
            ArrayList(default.resultObject).GetText(3).ToString()
        ==  "complexString");
    TEST_ExpectTrue(ArrayList(default.resultObject).GetFloat(4) == 45);
    TEST_ExpectNone(ArrayList(default.resultObject).GetItem(5));
    TEST_ExpectTrue(ArrayList(default.resultObject).GetBool(6));
}

protected static function CheckValuesAfterIncrement(HashTable root)
{
    local ArrayList jsonArray;
    TEST_ExpectTrue(root.GetBoolBy(P("/D")));
    TEST_ExpectTrue(root.GetFloatBy(P("/B/B")) == 10.12);
    TEST_ExpectTrue(
            root.GetTextBy(P("/A")).ToString()
        ==  "simpleValue!?");
    jsonArray = root.GetArrayListBy(P("/B/A"));
    TEST_ExpectTrue(jsonArray.GetBool(0));
    TEST_ExpectNotNone(jsonArray.GetHashTable(1));
    TEST_ExpectTrue(jsonArray.GetText(2).ToString() == "huh");
    TEST_ExpectTrue(jsonArray.GetText(3).ToString() ==  "complexString");
    TEST_ExpectTrue(jsonArray.GetFloat(4) == 45);
    TEST_ExpectNone(jsonArray.GetItem(5));
    TEST_ExpectTrue(jsonArray.GetBool(6));
    //  Test root itself
    TEST_ExpectTrue(root.GetLength() == 6);
    TEST_ExpectTrue(root.GetText(P("A")).ToString() == "simpleValue!?");
    TEST_ExpectTrue(root.GetItem(P("B")).class == class'HashTable');
    TEST_ExpectTrue(root.GetFloat(P("C")) == 5.5);
    TEST_ExpectTrue(root.GetBool(P("D")));
    TEST_ExpectTrue(root.GetText(P("E")).ToString() == "str");
    TEST_ExpectTrue(root.GetFloat(P("F")) == 45);
}

protected static function IncrementExpectingFail(
    LocalDatabaseInstance   db,
    string                  pointer,
    AcediaObject            value)
{
    local Text                  pointerAsText;
    local JSONPointer           jsonPointer;
    local DBIncrementTask  task;
    pointerAsText = __().text.FromString(pointer);
    jsonPointer = __().json.Pointer(pointerAsText);
    task = db.IncrementData(__().json.Pointer(pointerAsText), value);
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_InvalidData);
    jsonPointer.FreeSelf();
    pointerAsText.FreeSelf();
}

protected static function SubTest_IncrementRewriteBool(
    LocalDatabaseInstance   db,
    ArrayList               templateArray,
    HashTable               templateObject)
{
    Issue("JSON boolean values are rewritten by non-boolean values.");
    IncrementExpectingFail(db, "/D", none);
    IncrementExpectingFail(db, "/D", db);
    IncrementExpectingFail(db, "/D", __().box.int(23));
    IncrementExpectingFail(db, "/D", __().ref.float(-12));
    IncrementExpectingFail(db, "/D", __().text.FromStringM("Random!"));
    IncrementExpectingFail(db, "/D", templateArray);
    IncrementExpectingFail(db, "/D", templateObject);
    ReadFromDB(db, "");
    CheckValuesAfterIncrement(default.resultData);
}

protected static function SubTest_IncrementRewriteNumeric(
    LocalDatabaseInstance   db,
    ArrayList               templateArray,
    HashTable               templateObject)
{
    Issue("JSON numeric values are rewritten by non-numeric values.");
    IncrementExpectingFail(db, "/B/B", none);
    IncrementExpectingFail(db, "/B/B", db);
    IncrementExpectingFail(db, "/B/B", __().box.bool(true));
    IncrementExpectingFail(db, "/B/B", __().text.FromStringM("Random!"));
    IncrementExpectingFail(db, "/B/B", templateArray);
    IncrementExpectingFail(db, "/B/B", templateObject);
    ReadFromDB(db, "");
    CheckValuesAfterIncrement(default.resultData);
}

protected static function SubTest_IncrementRewriteString(
    LocalDatabaseInstance   db,
    ArrayList               templateArray,
    HashTable               templateObject)
{
    Issue("JSON string values are rewritten by non-`Text`/`MutableText`"
        @ "values.");
    IncrementExpectingFail(db, "/A", none);
    IncrementExpectingFail(db, "/A", db);
    IncrementExpectingFail(db, "/A", __().box.bool(true));
    IncrementExpectingFail(db, "/A", __().box.int(23));
    IncrementExpectingFail(db, "/A", __().ref.float(-12));
    IncrementExpectingFail(db, "/A", templateArray);
    IncrementExpectingFail(db, "/A", templateObject);
    ReadFromDB(db, "");
    CheckValuesAfterIncrement(default.resultData);
}

protected static function SubTest_IncrementRewriteObject(
    LocalDatabaseInstance   db,
    ArrayList               templateArray,
    HashTable               templateObject)
{
    Issue("JSON objects are rewritten by non-`HashTable` values.");
    IncrementExpectingFail(db, "", none);
    IncrementExpectingFail(db, "", db);
    IncrementExpectingFail(db, "", __().box.bool(true));
    IncrementExpectingFail(db, "", __().box.int(23));
    IncrementExpectingFail(db, "", __().ref.float(-12));
    IncrementExpectingFail(db, "", __().text.FromStringM("Random!"));
    IncrementExpectingFail(db, "", templateArray);
    ReadFromDB(db, "");
    CheckValuesAfterIncrement(default.resultData);
}

protected static function SubTest_IncrementRewriteArray(
    LocalDatabaseInstance   db,
    ArrayList               templateArray,
    HashTable               templateObject)
{
    Issue("JSON arrays are rewritten by non-`ArrayList` values.");
    IncrementExpectingFail(db, "/B/A", none);
    IncrementExpectingFail(db, "/B/A", db);
    IncrementExpectingFail(db, "/B/A", __().box.bool(true));
    IncrementExpectingFail(db, "/B/A", __().box.int(23));
    IncrementExpectingFail(db, "/B/A", __().ref.float(-12));
    IncrementExpectingFail(db, "/B/A", __().text.FromStringM("Random!"));
    IncrementExpectingFail(db, "/B/A", templateObject);
    ReadFromDB(db, "");
    CheckValuesAfterIncrement(default.resultData);
}

protected static function SubTest_IncrementMissing(LocalDatabaseInstance db)
{
    local DBIncrementTask task;
    Issue("New values are created in database after incrementing with path"
        @ "pointing to non-existing value.");
    task = db.IncrementData(__().json.Pointer(P("/L")), __().box.int(345));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    db.IncrementData(__().json.Pointer(P("/B/A/1//10")), none);
    task = db.IncrementData(__().json.Pointer(P("/B/A/1//-")),
                            __().box.int(85));
    task.connect = DBIncrementHandler;
    task.TryCompleting();
    TEST_ExpectTrue(default.resultType == DBR_Success);
    db.CheckDataType(__().json.Pointer(P("/L"))).connect = DBCheckHandler;
    ReadFromDB(db, "/B/A/1/");
    TEST_ExpectTrue(default.resultDataType == JSON_Number);
    TEST_ExpectTrue(ArrayList(default.resultObject).GetLength() == 12);
    TEST_ExpectTrue(ArrayList(default.resultObject).GetInt(11) == 85);
}

defaultproperties
{
    caseGroup   = "Database"
    caseName    = "Local database"
}