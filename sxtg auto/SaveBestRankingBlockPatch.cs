using System.Collections.Generic;
using System.Reflection;
using HarmonyLib;
using MelonLoader;

namespace SxtgAuto
{
    /// <summary>
    /// 오토플레이 결과가 베스트 스코어와 서버 랭킹에 반영되지 않도록 결과 저장 진입점만 차단
    /// </summary>
    [HarmonyPatch]
    internal static class SaveBestRankingBlockPatch
    {
        private static readonly HashSet<string> LoggedBlocks = new HashSet<string>();

        private static IEnumerable<MethodBase> TargetMethods()
        {
            foreach (var method in new[]
            {
                Find("RhythmGame.Result.ManagerResult", "PostRequestPlayResult"),
                Find("RhythmGame.Result.ManagerResult", "ComparePlayResultHighScore")
            })
            {
                if (method != null)
                    yield return method;
            }
        }

        private static MethodBase Find(string typeName, string methodName)
        {
            var type = AccessTools.TypeByName(typeName);
            return type == null ? null : AccessTools.Method(type, methodName);
        }

        private static bool Prefix(MethodBase __originalMethod)
        {
            if (!Main.BlockSaveBestRanking)
                return true;

            var name = __originalMethod == null
                ? "unknown"
                : __originalMethod.DeclaringType.FullName + "." + __originalMethod.Name;

            if (LoggedBlocks.Add(name))
                MelonLogger.Msg("[차단] 오토플레이 저장/베스트/랭킹 차단: " + name);

            return false;
        }
    }
}
