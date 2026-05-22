using System;
using HarmonyLib;
using MelonLoader;
using UnityEngine.SceneManagement;

[assembly: MelonInfo(typeof(SxtgAuto.Main), "SXTG Auto", "1.0.0", "hwa")]
[assembly: MelonGame("Lyrebird Studio", "Sixtar Gate STARTRAIL")]

namespace SxtgAuto
{
    public class Main : MelonMod
    {
        // 오토플레이 활성화 여부 (플레이 씬에서만 true)
        public static bool AutoPlayEnabled = false;

        // 오토플레이로 시작한 플레이 결과가 저장/베스트/랭킹에 반영되지 않도록 유지
        public static bool BlockSaveBestRanking = false;

        // 게임이 갱신하는 현재 시간(초) - ManagerPlay 등에서 후킹으로 채움
        public static float CurrentTimeSeconds = -1f;
        
        public override void OnInitializeMelon()
        {
            LoggerInstance.Msg("=== SXTG Auto 모드 초기화 ===");

            // Harmony 패치 적용 (실제 동작은 AutoPlayEnabled로 가드됨)
            var harmony = new HarmonyLib.Harmony("com.hwa.sxtgauto");
            harmony.PatchAll(typeof(Main).Assembly);

            // 씬 감지로 오토플레이 자동 ON/OFF
            try
            {
                SceneManager.activeSceneChanged += OnActiveSceneChanged;
                // 초기 씬도 반영
                ApplyAutoPlayByScene(SceneManager.GetActiveScene().name);
                LoggerInstance.Msg("씬 감지: Play 계열 씬에서 자동으로 오토플레이 ON/OFF");
            }
            catch (Exception ex)
            {
                LoggerInstance.Warning($"씬 감지 등록 실패: {ex.Message}");
            }

            LoggerInstance.Msg("초기화 완료!");
        }

        private static void OnActiveSceneChanged(Scene prev, Scene next)
        {
            ApplyAutoPlayByScene(next.name);
        }

        private static bool IsPlaySceneName(string sceneName)
        {
            if (string.IsNullOrEmpty(sceneName)) return false;
            // 너무 빡세게 고정하면 버전에 따라 깨질 수 있어서 contains 위주로
            var s = sceneName.ToLowerInvariant();
            return s.Contains("play") || s.Contains("rhythm") || s.Contains("game");
        }

        private static void ApplyAutoPlayByScene(string sceneName)
        {
            var shouldEnable = IsPlaySceneName(sceneName);
            if (shouldEnable)
                BlockSaveBestRanking = true;

            if (AutoPlayEnabled == shouldEnable) return;

            AutoPlayEnabled = shouldEnable;
            if (!AutoPlayEnabled)
                CurrentTimeSeconds = -1f; // 씬 이탈 시 stale time 방지
            MelonLogger.Msg($"[씬] {sceneName} -> 오토플레이 {(AutoPlayEnabled ? "ON" : "OFF")}");
        }
    }
}

