/**
 *  Set of tests related to `LoggerAPI`.
 *      Copyright 2021 Anton Tarasenko
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
class TEST_LogMessage extends TestCase
    abstract;

//  Short-hand for creating disposable `Text` out of a `string`
//  We need it, since `P()` always returns the same value, which might lead to
//  a conflict.
protected static function Text A(string message)
{
    return __().text.FromString(message);
}

//  Short-hand for quickly producing `LogMessage.Definition`
protected static function LoggerAPI.Definition DEF(string message)
{
    local LoggerAPI.Definition result;
    result.m = message;
    return result;
}

protected static function TESTS()
{
    Context("Testing how `LogMessage` collects given arguments.");
    Test_SimpleArgumentCollection();
    Test_ArgumentCollection();
    Test_ArgumentCollectionOrder();
    Test_TypedArgumentCollection();
}

protected static function Test_SimpleArgumentCollection()
{
    local LogMessage message;
    Issue("`Text` arguments are not correctly pasted.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Message %1and%2: %3"));
    message.Arg(A("umbra")).Arg(A("mumbra")).Arg(A("eleven! "));
    TEST_ExpectTrue(    message.Collect().ToString()
                    ==  "Message umbraandmumbra: eleven! ");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("%1 - was pasted."));
    message.Arg(A("Heheh"));
    TEST_ExpectTrue(message.Collect().ToString() == "Heheh - was pasted.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("This %%%1 and that %2"));
    message.Arg(A("one")).Arg(A("two"));
    TEST_ExpectTrue(    message.Collect().ToString()
                    ==  "This %%one and that two");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("%1%2"));
    message.Arg(A("one")).Arg(A("two"));
    TEST_ExpectTrue(message.Collect().ToString() == "onetwo");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("%1"));
    message.Arg(A("only"));
    TEST_ExpectTrue(message.Collect().ToString() == "only");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Just some string."));
    TEST_ExpectTrue(message.Collect().ToString() == "Just some string.");
}

protected static function Test_ArgumentCollection()
{
    local LogMessage message;
    Issue("`Text` arguments are not correctly collected after reset.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("This %1 and that %2"));
    message.Arg(A("one")).Arg(A("two")).Reset().Arg(A("huh")).Arg(A("muh"));
    TEST_ExpectTrue(    message.Collect().ToString()
                        == "This huh and that muh");

    Issue("`Text` arguments are not correctly collected after specifying"
        @ "too many.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Just %1, %2, %3, %4 and %5"));
    message.Arg(A("1")).Arg(A("2")).Arg(A("3")).Arg(A("4")).Arg(A("5"))
        .Arg(A("6")).Arg(A("7"));
    TEST_ExpectTrue(    message.Collect().ToString()
                        == "Just 1, 2, 3, 4 and 5");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Just"));
    TEST_ExpectTrue(message.Arg(A("arg")).Collect().ToString() == "Just");

    Issue("`Text` arguments are not correctly collected after specifying"
        @ "too little.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Just %1, %2, %3, %4 and %5"));
    message.Arg(A("1")).Arg(A("2")).Arg(A("3"));
    TEST_ExpectTrue(    message.Collect().ToString()
                        == "Just 1, 2, 3,  and ");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Maybe %1"));
    TEST_ExpectTrue(message.Collect().ToString() == "Maybe ");
}

protected static function Test_ArgumentCollectionOrder()
{
    local LogMessage message;
    Issue("`Text` arguments are not correctly collected if are not specified"
        @ "in order.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("This %2 and that %1"));
    message.Arg(A("huh")).Arg(A("muh"));
    TEST_ExpectTrue(    message.Collect().ToString()
                        == "This muh and that huh");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Just %5, %3, %4, %1 and %2"));
    message.Arg(A("1")).Arg(A("2")).Arg(A("3")).Arg(A("4")).Arg(A("5"));
    TEST_ExpectTrue(    message.Collect().ToString()
                        == "Just 5, 3, 4, 1 and 2");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));

    Issue("`Text` arguments are not correctly collected if are not specified"
        @ "in order and not enough of them was specified.");
    message.Initialize(DEF("Just %5, %3, %4, %1 and %2"));
    message.Arg(A("1")).Arg(A("2")).Arg(A("3"));
    TEST_ExpectTrue(    message.Collect().ToString()
                        == "Just , 3, , 1 and 2");
}

protected static function Test_TypedArgumentCollection()
{
    local LogMessage message;
    Issue("`int` arguments are not correctly collected.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Int: %1"));
    TEST_ExpectTrue(message.ArgInt(-7).Collect().ToString()
                        == "Int: -7");

    Issue("`float` arguments are not correctly collected.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Float: %1"));
    TEST_ExpectTrue(message.ArgFloat(3.14).Collect().ToString()
                        == "Float: 3.14");

    Issue("`bool` arguments are not correctly collected.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Bool: %1 and %2"));
    TEST_ExpectTrue(message.ArgBool(true).ArgBool(false).Collect()
        .ToString() == "Bool: true and false");

    Issue("`Class` arguments are not correctly collected.");
    message = LogMessage(__().memory.Allocate(class'LogMessage'));
    message.Initialize(DEF("Class: %1"));
    TEST_ExpectTrue(message.ArgClass(class'M14EBRBattleRifle').Collect()
        .ToString() == "Class: KFMod.M14EBRBattleRifle");
}

defaultproperties
{
    caseGroup   = "Logger"
    caseName    = "LogMessage"
}