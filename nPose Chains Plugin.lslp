integer lmChannel = -8888;
float fGravity=0.3;
float fLife=1.0;
float fMinSpeed = 0.005;
float fMaxSpeed = 0.005;
float fSizeX=0.07;
float fSizeY=0.07;
float fRed=1.0;
float fGreen=1.0;
float fBlue=1.0;

integer I_Am_Sender;
integer I_Am_Dest;

key kTarget;
key kTexture = "245ea72d-bc79-fee3-a802-8e73c0f09473";
string  gSET_MAIN_SEPARATOR            = "|"; // separator from linkmessage
string  gSET_SEPARATOR                = "~"; // separator from linkmessage
integer gPLUGIN_COMMAND_REGISTER    = 310;

integer gCMD_SET_CHAINS = 2732; // cmdId, set chains in msg
integer gCMD_REM_CHAINS = 2733; // cmdId, remove all chains
integer gCMD_CONFIG     = 2734; // cmdId, config in msg
// --- global variables ---
list    gPrimIDs;         // description => linkId
integer gListenLMHandle;  // storing lockguard listening handle
list    gCommandQueue;    //3-strided list: [cmdId, avatarKey, commandParamsString]
list    paramsList;
integer STRIDE = 9;
integer index;

query_set_config(key avatarKey, list items) {
    integer i;
    integer stop = llGetListLength(items);
    for (i=0; i<stop; ++i) {
        list line = llParseString2List(llList2String(items, i), ["="], []);
        string item = llList2String(line, 0);
        if (llGetInventoryType(llList2String(line, 1)) == 0) {
            kTexture = llGetInventoryKey(llList2String(line, 1));
         }
        else if ((key)llList2String(line, 1)) {
            kTexture =(key)llList2String(line, 1);
        }
        else if(llToLower(item) == "xsize")   fSizeX   = (float)llList2String(line, 1);
        else if(llToLower(item) == "ysize")   fSizeY   = (float)llList2String(line, 1);
        else if(llToLower(item) == "gravity") fGravity = (float)llList2String(line, 1);
        else if(llToLower(item) == "life")    fLife    = (float)llList2String(line, 1);
        else if(llToLower(item) == "red")     fRed     = (float)llList2String(line, 1);
        else if(llToLower(item) == "green")   fGreen   = (float)llList2String(line, 1);
        else if(llToLower(item) == "blue")    fBlue    = (float)llList2String(line, 1);
    }
}

query_config(key avatarKey, list items) {
    integer i;
    //first need to process the first item which will be SENDERS (the linked prims where particles originate)
    //Make a list to hold SENDER and params
    /*
    stride = 9
    paramsList =
    [
        param 0 = SENDER,
        param 1 = texture,
        param 2 = xsize,
        param 3 = ysize
        param 4 = gravity,
        param 5 = life,
        param 6 = red,
        param 7 = green,
        param 8 = blue
    ]
    */
    list line = llParseString2List(llList2String(items, i), ["="], []);
    list senders = llCSV2List(llList2String(line, 1));
    string item = llList2String(line, 0);
    if (llToLower(item) == "sender") {
        list senders = llCSV2List(llList2String(line, 1));
        if (llToLower(llList2String(senders, 0)) == "clear") {
            paramsList = [];
            index = 0;
            return;
        }
        else if(llToLower(llList2String(senders, 0)) == "change_defaults") {
            query_set_config(avatarKey, items);
            return;
        }
        integer stop = llGetListLength(senders);
        integer n;
        for (n=0; n<stop; ++n) {
            if (llListFindList(gPrimIDs, [llList2String(senders, n)]) > -1) {
                paramsList += [llList2String(senders, n), kTexture, fSizeX, fSizeY,fGravity, fLife, fRed, fGreen, fBlue];
            }
        }
//        llOwnerSay("before, paramslist:\n\n" + llList2CSV(paramsList));
        senders = [];
        items = llDeleteSubList(items, 0,0);
        //Step thru all the sender names in the paramsList and finish populating the params in the list
        integer paramsLength = llGetListLength(paramsList)/STRIDE;
        for (index=index; index<paramsLength; ++index) {
            integer length = llGetListLength(items);
            for(i=0; i < length; ++i) {
                line = llParseString2List(llList2String(items, i), ["="], []);
                string item = llList2String(line, 0);
                if (llGetInventoryType(llList2String(line, 1)) == 0) {
                    paramsList = llListReplaceList(paramsList, [llGetInventoryKey(llList2String(line, 1))], (index*9)+1, (index*9)+1);
                 }
                else if ((key)llList2String(line, 1)) {
                    paramsList = llListReplaceList(paramsList, [(key)llList2String(line, (index*9)+1)], (index*9)+1, (index*9)+1);
                }
                else if (item == "xsize")   {
                    paramsList = llListReplaceList(paramsList, [(float)llList2String(line, 1)], (index*9)+2, (index*9)+2);
                 }
                else if (item == "ysize")   {
                    paramsList = llListReplaceList(paramsList, [(float)llList2String(line, 1)], (index*9)+3, (index*9)+3);
                 }
                else if (item == "gravity") {
                    paramsList = llListReplaceList(paramsList, [(float)llList2String(line, 1)], (index*9)+4, (index*9)+4);
                 }
                else if (item == "life")    {
                    paramsList = llListReplaceList(paramsList, [(float)llList2String(line, 1)], (index*9)+5, (index*9)+5);
                 }
                else if (item == "red")     {
                    paramsList = llListReplaceList(paramsList, [(float)llList2String(line, 1)], (index*9)+6, (index*9)+6);
                 }
                else if (item == "green")   {
                    paramsList = llListReplaceList(paramsList, [(float)llList2String(line, 1)], (index*9)+7, (index*9)+7);
                }
                else if (item == "blue")    {
                    paramsList = llListReplaceList(paramsList, [(float)llList2String(line, 1)], (index*9)+8, (index*9)+8);
                }
            }
        }
    }
}

SetParticles(integer linkNum) {
    key Texture = kTexture;
    float SizeX = fSizeX;
    float SizeY = fSizeY;
    float Gravity = fGravity;
    float Life = fLife;
    float Red = fRed;
    float Green = fGreen;
    float Blue = fBlue;
    integer index = llListFindList(paramsList, [llList2String(llGetLinkPrimitiveParams(linkNum, [PRIM_DESC]),0)]);
    if (index > -1) {
//    llOwnerSay("in setparticles, " + llList2String(llGetLinkPrimitiveParams(linkNum, [PRIM_DESC]),0) + ",\n paramsList:\n" + llList2CSV(paramsList));
        if ((string)llList2Key(paramsList, index + 1) != "") Texture = llList2Key(paramsList, index + 1);
        if ((string)llList2Float(paramsList, index + 2) != "") SizeX = llList2Float(paramsList, index + 2);
        if ((string)llList2Float(paramsList, index + 3) != "") SizeY = llList2Float(paramsList, index + 3);
        if ((string)llList2Float(paramsList, index + 4) != "") Gravity = llList2Float(paramsList, index + 4);
        if ((string)llList2Float(paramsList, index + 5) != "") Life = llList2Float(paramsList, index + 5);
        if ((string)llList2Float(paramsList, index + 6) != "") Red = llList2Float(paramsList, index + 6);
        if ((string)llList2Float(paramsList, index + 7) != "") Green = llList2Float(paramsList, index + 7);
        if ((string)llList2Float(paramsList, index + 8) != "") Blue = llList2Float(paramsList, index + 8);
    }

    integer nBitField = PSYS_PART_TARGET_POS_MASK|PSYS_PART_FOLLOW_VELOCITY_MASK;
    llLinkParticleSystem(linkNum, []);
    if(fGravity == 0) nBitField = nBitField|PSYS_PART_TARGET_LINEAR_MASK;
//llOwnerSay("index: " + (string)index + ", sender: " + llList2String(llGetLinkPrimitiveParams(linkNum, [PRIM_DESC]),0) + "\nparams: " + llList2CSV([Texture,SizeX,SizeY,Gravity,Life,Red,Green,Blue]) + "\n");
    llLinkParticleSystem(linkNum,
    [ 
        PSYS_PART_MAX_AGE, fLife, 
        PSYS_PART_FLAGS, nBitField, 
        PSYS_PART_START_COLOR, <Red, Green, Blue>, 
        PSYS_PART_END_COLOR, <Red, Green, Blue>, 
        PSYS_PART_START_SCALE, <SizeX, SizeY, 1.00000>, 
        PSYS_PART_END_SCALE, <SizeX, SizeY, 1.00000>, 
        PSYS_SRC_PATTERN, 1, 
        PSYS_SRC_BURST_RATE, 0.000000, 
        PSYS_SRC_ACCEL, <0.00000, 0.00000, (Gravity*-1)>, 
        PSYS_SRC_BURST_PART_COUNT, 10, 
        PSYS_SRC_BURST_RADIUS, 0.000000, 
        PSYS_SRC_BURST_SPEED_MIN, fMinSpeed, 
        PSYS_SRC_BURST_SPEED_MAX, fMaxSpeed, 
        PSYS_SRC_INNERANGLE, 0.000000, 
        PSYS_SRC_OUTERANGLE, 0.000000, 
        PSYS_SRC_OMEGA, <0.00000, 0.00000, 0.00000>, 
        PSYS_SRC_MAX_AGE, 0.000000, 
        PSYS_PART_START_ALPHA, 1.000000, 
        PSYS_PART_END_ALPHA, 1.000000, 
        PSYS_SRC_TARGET_KEY, kTarget, 
        PSYS_SRC_TEXTURE, Texture 
    ]);
}

query_set_chains(key avatarKey, list items) {
    integer itemLength = llGetListLength(items);
    integer i;
    for(i=0; i < itemLength; i+=2) {
        
        string senderDesc    = llList2String(items, i);
        integer senderIndex  = llListFindList(gPrimIDs, [senderDesc]);
        key validSenderKey = (key)llList2String(gPrimIDs, senderIndex + 2);
        if(validSenderKey) {              //True if we have a key so we've found the sender of the chains so set a flag variable.
            I_Am_Sender = 1;
        }
        
        string targetDesc    = llList2String(items, i + 1);
        integer targetIndex = llListFindList(gPrimIDs, [targetDesc]);
        key validTargetKey = (key)llList2String(gPrimIDs, targetIndex + 2);
        if(validTargetKey) {
            // We have the target for the chains now.. 
            if(!I_Am_Dest) I_Am_Dest = 1;
            llSleep(1);
            string sendText = senderDesc + "," + llList2String(gPrimIDs, targetIndex + 2);
            llWhisper(lmChannel, senderDesc + "," + llList2String(gPrimIDs, targetIndex + 2));
        }
    }
}

query_rem_chains(list items) {
    if(I_Am_Sender) {
        integer itemLength = llGetListLength(items);
        integer i;
        for(i=0; i < itemLength; ++i) {
            integer xLength = llGetListLength(gPrimIDs);
            integer x;
            for(x=0; x < xLength; ++x) {
                if(llList2String(items, i) == llList2String(gPrimIDs, x)) {
                    llLinkParticleSystem((integer)llList2String(gPrimIDs, x+1) , []);
                }
            }
        }
    }
}

executeCommands() {
    while(llGetListLength(gCommandQueue)) {
        integer commandId=llList2Integer(gCommandQueue, 0);
        key avatarKey=llList2Key(gCommandQueue, 1);
        list params;
        if( commandId == gCMD_REM_CHAINS ) {
            params=llParseStringKeepNulls(llList2String(gCommandQueue, 2), [gSET_SEPARATOR], []);
            query_rem_chains(params);
            gCommandQueue=llDeleteSubList(gCommandQueue, 0, 2);
        }
        else if(commandId == gCMD_SET_CHAINS) {
            params=llParseStringKeepNulls(llList2String(gCommandQueue, 2), ["~"], []);
            query_set_chains(avatarKey, params);
            gCommandQueue=llDeleteSubList(gCommandQueue, 0, 2);
        }
        else if(commandId == gCMD_CONFIG) {
            params=llParseStringKeepNulls(llList2String(gCommandQueue, 2), [gSET_SEPARATOR], []);
            query_config(avatarKey, params);
            gCommandQueue=llDeleteSubList(gCommandQueue, 0, 2);
        }
    }
}

default {
    state_entry() {
        integer number_of_prims = llGetNumberOfPrims();
        integer i;
        for(i=0; i < number_of_prims + 1; ++i) { //Walk throug the whole linkset including a single prim
            string desc = llList2String(llGetLinkPrimitiveParams( i, [ PRIM_DESC ]), 0);
            key linkedKey = llGetLinkKey(i);
            if(desc != "" && desc != "(No description)") {
                if(-1 == llListFindList( gPrimIDs, [desc])) { // only accept unique descriptions
                    gPrimIDs += [desc, i, linkedKey];
                }
            }
        }
        llMessageLinked(LINK_SET, gPLUGIN_COMMAND_REGISTER, llDumpList2String(["CHAINS_ADD", gCMD_SET_CHAINS, 1, 0], "|"), "");
        llMessageLinked(LINK_SET, gPLUGIN_COMMAND_REGISTER, llDumpList2String(["CHAINS_REMOVE", gCMD_REM_CHAINS, 1, 0], "|"), "");
        llMessageLinked(LINK_SET, gPLUGIN_COMMAND_REGISTER, llDumpList2String(["CHAINS_CONFIG", gCMD_CONFIG, 1, 0], "|"), "");
        key MyParentId = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
        lmChannel = (integer)("0x7F" + llGetSubString((string)MyParentId, 0, 5));
        if(MyParentId == llGetOwner()) lmChannel = (integer)("0x7F" + llGetSubString((string)llGetKey(), 0, 5));
        gListenLMHandle = llListen(lmChannel, "", NULL_KEY, "");
    }

    link_message(integer sender, integer num, string str, key id) {
        if(num == gCMD_REM_CHAINS || num == gCMD_SET_CHAINS || num == gCMD_CONFIG) {
            gCommandQueue+=[num, id, str];
            executeCommands();
        }
    }

    listen(integer channel, string cuffName, key cuffKey, string message) {
        list temp = llCSV2List(message);
        string senderCheck = llList2String(temp, 0);
        key destination = (key)llList2String(temp, 1);
        if(channel == lmChannel && I_Am_Sender == 1 && llListFindList(gPrimIDs, [senderCheck]) != -1) {
            integer IDIndex = llListFindList(gPrimIDs, [senderCheck]) + 1;
            kTarget = destination;
            SetParticles(llList2Integer(gPrimIDs, IDIndex));
        }
    }

    changed(integer change) {
        if(change & CHANGED_LINK) {
//           llResetScript();
        }
    }

    on_rez(integer params) {
        llResetScript();
    }
}
