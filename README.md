# Исходный код сборки игры Counter-Strike 1.6 сервера CSOMOD.RU | Зомби вокруг нас 

Если у кого-то есть желание помочь с готовым сервером, пишите - постараюсь в свободное время исправить. Предупреждаю сразу, что код там не огонь, и возможно все с первого тыка не заработает. Если есть желание внести какие-то корректировки, то обращайтесь в телеграм беседу https://t.me/csomod

## Минималные требования
- Linux (Сам сервер стоял на Debian 12);
- MySQL 10.11.4. Работа части СУБД допом проверялась на MariaDB 11.6.2 - на этой версии почему-то не работают сейвы. Если есть желание разобраться, пишите добавлю тогда исправления в общий репозиторий;
- ReHLDS;
- AmxModX 1.9.0;
- ReAPI.

## Инструкция по установке
### 1. Установка схем БД
Импортируйте код из файла db/scheme.sql в вашу БД. Обратите внимание, чтобы после импорта появились 4 таблички и 4 процедуры БД.

<img width="250" height="139" alt="image" src="https://github.com/user-attachments/assets/7ed30577-cc06-47d4-b043-7f8a0495e689" />
<img width="248" height="125" alt="image" src="https://github.com/user-attachments/assets/61ff1678-8b60-4199-98e6-c64d1b06944d" />

### 2. Установка сборки сервера
Важно понимать, что на этом этапе у Вас уже должен быть установлен сервер с ReHLDS. Обычно на игровых хостингах сразу предоставляют такую услугу.
Скачайте серверные файлы сборки по следующему адресу. [Скачать сборку.](https://drive.google.com/file/d/1SwTPH_YLUzC8wfT4H7Lo7v0L0tckazEH/view?usp=sharing) Обратите внимание, что все последующие пути файлов и папок в этом пункте будут обращены касательно архива из ссылки.
Распакуйте архив. Опуститесь в папку ZVN/cstrike перенесите на сервер в соответствующую папку рекурсивно БЕЗ ЗАМЕНЫ существующих файлов следующие папки:
- gfx
- maps
- models
- overviews
- resource
- sound
- sprites
<img width="887" height="581" alt="image" src="https://github.com/user-attachments/assets/bc8d8dbc-8ccb-42c8-bee1-8b871f564f43" />

В этой же папке скопируйте и перенесите на сервер все *.wad *.cfg файлы в cstrike на сервере.
Теперь опуститесь в папку ZVN/cstrike/addons. Скопируйте рекурсивно С ЗАМЕНОЙ существующих файлов следующие папки на сервер:
- amxmodx
- reunion
- PrintCenterFix
- unprecacher
- hitbox_fix
- VoiceTranscoder
<img width="797" height="466" alt="image" src="https://github.com/user-attachments/assets/0238fcf3-da2d-4772-bf10-229f8b5219f1" />

На вашем сервере откройте /cstrike/addons/metamod/plugins.ini и пропишите следующие строки:
`
linux addons/amxmodx/dlls/amxmodx_mm_i386.so
linux addons/reunion/reunion_mm_i386.so
linux addons/VoiceTranscoder/VoiceTranscoder.so
linux addons/PrintCenterFix/printcenterfix_mm_i386.so
linux addons/unprecacher/unprecacher_i386.so
linux addons/hitbox_fix/hitbox_fix_mm_i386.so
`
#### 2.1 Установка дополнительных ресурсов (простой вариант)
Если вы не знаете что такое nginx, то просто скопируйте рекурсивно без замены все файлы из ZVN/fastdl/* в папку /cstrike.

В параметрах запуска сервера пропишите `-heapsize 524288` или если нет возможности, то обратитесь в тех поддержку вашего хостинга.

### 2.2 Установка дополнительных ресурсов (продвинутый вариант)
Если у вас арендован готовый игровой сервер, то навряд ли получится так сделать. В любом случае, вы можете воспользоваться вариантом из п. 2.1.

Для остальных советую настроить FastDL nginx сервер так: 
1. Скопируйте файлы ZVN/fastdl в fastdl на вашем сервере.
2. При обращения клиента на http-сервер должна сначала проверяться папка fastdl -> если файл найден, то он скачивается.
3. Файл не найден и теперь он ищется в папке cstrike. Если файл найден, то файл скачивается.
4. Не забываем, что есть ресурсы и в папке valve. Её также нужно прогнать.

В параметрах запуска сервера пропишите `-heapsize 524288` или если нет возможности, то обратитесь в тех поддержку вашего хостинга.

### 2.3 Подключение FastDL сервера

Не забудьте заменить адрес http сервера в cstrike/fastdl.cfg в конфиге в параметре sv_downloadurl

<img width="592" height="177" alt="image" src="https://github.com/user-attachments/assets/c4f5ee25-ac75-498d-95b2-aa49b3971940" />



### 3. Подключение к СУБД игрового сервера
Все действия по компиляции плагинов выполнялись на Windows.
Советую скачать [VSCode](https://code.visualstudio.com/download?_exp_download=fb315fc982) и установить расширение [AMXX Pawn language](https://marketplace.visualstudio.com/items?itemName=KliPPy.amxxpawn-language)
Склонируйте текущий репозиторий к себе на компьютер и откройте проект через VSCode.
Откройте файл source/zpe_mysql_main.sma 
Измените данные подключения к БД на свои (Та БД, в которую импортировалсь схема из п. 1)
Нажмите ctrl + shift + b. Произойдет компиляция плагина. Скопируйте скомпилированный плагин со своего пк на сервер ./complited -> /cstrike/addons/amxmodx/plugins

<img width="1560" height="1155" alt="image" src="https://github.com/user-attachments/assets/56ea31a8-6740-4b8e-8c10-a97ff48d0767" />

Можете запускать и играть (но я не уверен)
