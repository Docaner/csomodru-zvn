#if defined _top5cam_included
    #endinput
#endif

#define _top5cam_included

enum CamState:
{
    //Анимация камеры отключена
    CAM_DISABLED = 0,
    //Задержка включения эмоций игрока
    CAM_EMOTION,
    //Эффект потухания экрана
    CAM_EFFECT,
    //Камера двигается
    CAM_MOVING,
    //Камера стоит статично
    CAM_STATIC 
}

/**
 * Запускает сцену с камерой
 * 
 * @return      true если сцена запустилась,
 *              false нет данных для сцены
 */
native bool:top5_camera_start();

/**
 * Время проигрывания сцены
 * 
 * @return время проигрывания сцены
 */
native Float:get_top5camera_time();

/**
 * Получает стадию работы камеры CamState 
 */
native CamState:get_top5camera_state();

/**
 * Событие вызова старта сцены топ5
 */
forward top5cam_started();