using System;
using System.Collections;
using System.Reflection;
using HarmonyLib;
using RhythmGame.Play;

namespace SxtgAuto
{
    /// <summary>
    /// 플레이 씬에서만 동작하는 오토플레이 패치
    /// (디버그용 리플렉션 덤프는 제거, 필요한 최소한만 1회 캐시)
    /// </summary>
    [HarmonyPatch]
    internal static class AutoPlayPatch
    {
        private static Action<RG_PS_Judgement, float, int> _autoPlayJudge;
        private static FieldInfo _noteJudgeCursorField;
        private static FieldInfo _numLanesField;

        /// <summary>
        /// currentTime 캡처용 패치 (ManagerPlay가 internal일 수 있어 문자열 기반 TargetMethod 사용)
        /// </summary>
        [HarmonyPatch]
        private static class TimeCapturePatch
        {
            private static MethodBase TargetMethod()
            {
                // 우선순위대로 타입 탐색
                var t =
                    AccessTools.TypeByName("RhythmGame.Play.ManagerPlay") ??
                    AccessTools.TypeByName("ManagerPlay");

                if (t == null) return null;

                // CheckGameFinished(float currentTime)
                return AccessTools.Method(t, "CheckGameFinished", new[] { typeof(float) });
            }

            private static void Prefix(float __0)
            {
                Main.CurrentTimeSeconds = __0;
            }
        }

        [HarmonyPostfix]
        [HarmonyPatch(typeof(RG_PS_Judgement), "Update")]
        private static void RG_PS_Judgement_Update_Postfix(RG_PS_Judgement __instance)
        {
            if (!Main.AutoPlayEnabled) return; // 플레이 씬에서만 true

            var curTime = Main.CurrentTimeSeconds;
            if (curTime < 0f) return;

            try
            {
                EnsureCaches();
                if (_autoPlayJudge == null) return;

                var laneCount = GetLaneCount(__instance);
                for (var lane = 0; lane < laneCount; lane++)
                {
                    _autoPlayJudge(__instance, curTime, lane);
                }
            }
            catch
            {
                // 게임 플레이 중 예외로 죽는 것 방지(조용히 무시)
            }
        }

        private static void EnsureCaches()
        {
            if (_autoPlayJudge == null)
            {
                var m = AccessTools.Method(typeof(RG_PS_Judgement), "AutoPlayJudge", new[] { typeof(float), typeof(int) });
                if (m != null)
                    _autoPlayJudge = AccessTools.MethodDelegate<Action<RG_PS_Judgement, float, int>>(m);
            }

            if (_noteJudgeCursorField == null)
                _noteJudgeCursorField = AccessTools.Field(typeof(RG_PS_Judgement), "noteJudgeCursor");
            if (_numLanesField == null)
                _numLanesField = AccessTools.Field(typeof(RG_PS_Judgement), "numLanes");
        }

        private static int GetLaneCount(RG_PS_Judgement instance)
        {
            try
            {
                // noteJudgeCursor 리스트 길이가 가장 안전(인덱스 범위 그대로 사용 가능)
                if (_noteJudgeCursorField != null)
                {
                    if (_noteJudgeCursorField.GetValue(instance) is IList list && list.Count > 0)
                        return list.Count;
                }

                // fallback: numLanes
                if (_numLanesField != null)
                {
                    var n = (int)_numLanesField.GetValue(instance);
                    if (n > 0 && n <= 10) return n;
                }
            }
            catch
            {
                // ignore
            }

            // 최후 fallback
            return 10;
        }
    }
}

