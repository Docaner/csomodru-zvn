#if defined _zmcso_quests_included
	#endinput
#endif
#define _zmcso_quests_included

/* =============================
    Квесты
=============================== */

//Данные квестов
enum Qst{
    Key = 0,      // Ключ
    Name,         // Название
    Desc,         // Описание 
    Cat,          // Сложность
    Finish,       // Количество действий для получения награды
    RewType,      // Тип награды
    RewAmount     // Количество награды
}

// Сложность квеста
enum Category{
    Easy = 0,   // Простой
    Medium,     // Средний
    Hard        // Сложный
}


/**
    Перевод значений сложности в строку

    @param cat - значение сложности
    @param szStr - строковое значение награды
    @param iSize - размер строки
    
    @noreturn
 */
stock catToStr(Category:cat, szStr[], iSize)
{
    switch(cat)
    {
        case Easy: formatex(szStr, iSize, "низкая");
        case Medium: formatex(szStr, iSize, "средняя");
        case Hard: formatex(szStr, iSize, "высокая");
    }
}


// Награды квестов
enum Rew{
    Money = 0,  // Деньги
    Ammo,       // Аммо
    Experience  // Опыт
}

/**
    Перевод значений наград в строку

    @param reward - значение награды
    @param szStr - строковое значение награды
    @param iSize - размер строки
    
    @noreturn
 */
stock rewToStr(Rew:reward, szStr[], iSize)
{
    switch(reward)
    {
        case Money: formatex(szStr, iSize, "$");
        case Ammo: formatex(szStr, iSize, " ammo");
        case Experience: formatex(szStr, iSize, " exp");
    }
}


/* =============================
    База данных
=============================== */

// Данные квестов игрока
enum User {
    ID = 0,     // Идентификатор квеста в БД
    QstID,      // Идентификатор квеста в системе
    StartTime,  // Начало времени
    EndTime,    // Конец времени
    Prog,       // Прогресс квеста
    Compl       // Выполнен ли квест
}

/**
    Регистрация квеста

    @param key - ключ квеста (должен быть уникальным)
    @param name - название квеста
    @param desc - описание квеста
    @param cat - категория квеста
    @param finish - количество очков, которое необходимо набрать для окончания квеста
    @param rewType - тип награды
    @param rewAmount - количество награды

    @return - дескриптор квеста (идентификатор квеста) 
 */
native q_register(const key[], const name[], const desc[], Category:cat, finish, Rew:rewType, rewAmount);


/**
    Получение идентификатора квеста игрока

    @param id - индекс игрока
    @param qstID - идентификатор квеста (из q_register)

    @return - идентификатор квеста игрока или -1, если не найден квест
 */

native q_get_user_quest(id, qstID);

/**
    Получение прогресса квеста игрока

    @param id - индекс клиента
    @param qstUsr - идентификатор квеста игрока (из q_get_user_quest)

    @return - прогресс игрока
 */
native q_get_user_progress(id, qstUsr);

/**
    Установка прогресса квеста игрока

    @param id - индекс игрока
    @param qstUsr - идентификатор квеста игрока (из q_get_user_quest)
    @param value - значение прогресса

    @noreturn
 */
native q_set_user_progress(id, qstUsr, value);