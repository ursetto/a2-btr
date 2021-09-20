// https://github.com/fadden/6502bench/blob/master/PluginCommon/Interfaces.cs
// https://github.com/fadden/6502bench/blob/master/PluginCommon/Util.cs

// Original license:
// Copyright 2019 faddenSoft. All Rights Reserved.
// See the LICENSE.txt file for distribution terms (Apache 2.0).

using System;
using System.Collections.Generic;

using PluginCommon;

namespace ExtensionScriptSample {
    /// <summary>
    /// Class for handling a JSR followed by a 1-byte position, then a string terminated with $FF.
    /// </summary>
    public class InlineBTRString: MarshalByRefObject, IPlugin, IPlugin_SymbolList,
            IPlugin_InlineJsr {
        private IApplication mAppRef;
        private byte[] mFileData;

        // Only one call.
        private const string LABEL_SUFFIX = "PRNTSTR";
        private Dictionary<int, PlSymbol> mBTRStringAddrs = new Dictionary<int, PlSymbol>();
        private int terminatingByte = 0xff;

        public string Identifier {
            get {
                return "Inline BTR string handler";
            }
        }

        public void Prepare(IApplication appRef, byte[] fileData, AddressTranslate addrTrans) {
            mAppRef = appRef;
            mFileData = fileData;

            mAppRef.DebugLog("InlineBTRString(id=" +
                AppDomain.CurrentDomain.Id + "): prepare()");
        }

        public void Unprepare() {
            mAppRef = null;
            mFileData = null;
        }

        public void UpdateSymbolList(List<PlSymbol> plSyms) {
            mBTRStringAddrs.Clear();

            foreach (PlSymbol sym in plSyms) {
                if (sym.Label.EndsWith(LABEL_SUFFIX)) {
                    mBTRStringAddrs.Add(sym.Value, sym);
                }
            }
            mAppRef.DebugLog(LABEL_SUFFIX + " matched " + mBTRStringAddrs.Count + " labels");
        }
        public bool IsLabelSignificant(string beforeLabel, string afterLabel) {
               return beforeLabel.EndsWith(LABEL_SUFFIX) || afterLabel.EndsWith(LABEL_SUFFIX);
        }

        public void CheckJsr(int offset, int operand, out bool noContinue) {
            noContinue = false;
            if (!mBTRStringAddrs.ContainsKey(operand)) {
                return;
            }

            // search for the terminating byte
            if (offset + 3 >= mFileData.Length) {
                mAppRef.DebugLog("Unable to find BTR formatting byte at +" +
                    (offset+3).ToString("x6"));
                return;
            }
            int termOff = offset + 3 + 1;
            while (termOff < mFileData.Length) {
                if (mFileData[termOff] == terminatingByte) {
                    break;
                }
                termOff++;
            }

            if (termOff == mFileData.Length) {
                mAppRef.DebugLog("Unable to find end of BTR string at +" +
                    (offset+3).ToString("x6"));
                return;
            }

            mAppRef.SetInlineDataFormat(offset + 3, 1, DataType.NumericLE, DataSubType.Hex, null);
            int strLength = termOff - (offset + 3 + 1);

            mAppRef.SetInlineDataFormat(offset + 3 + 1, strLength,
                DataType.StringGeneric, DataSubType.HighAscii, null);

            mAppRef.SetInlineDataFormat(offset + 3 + 1 + strLength, 1, DataType.NumericLE, DataSubType.Hex, null);
        }
    }
}
