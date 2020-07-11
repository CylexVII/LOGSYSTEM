# LOGSYSTEM
Bir süre önce bir şeyi dataya kaydetmeyi anlatmıştım. Şimdi daha gelişmiş halini paylaşıyorum :)

                                                                  ÖZELLİKLER
Bu log sistemiyle yere para atma ve oyuncuya para verme, yere kara para atma ve oyuncuya kara para verme, yere silah atma ve oyuncuya silah verme, bankadan para atma ve bankadan para alma, mesleklerdeki depolar, yapılan işlemler (fatura kesme, polislerin kimlik bakması) gibi logları tutmanızı sağlar :)

                                                                  DÜZENLEME
config.lua içerisinden logların discorddan gözükmesini istiyorsanız Config.Discord'u true yapın. SQL olarak istiyorsanız false yapın.
Logunun tutulmasını istemediğiniz logları config.lua içerisinden kapatabilirsiniz.



                                                                  KURULUM
1- Dosyayı indirin.
2- İçindeki CYLEX_LOGSYSTEM scriptini resources klasörüne atıp server.cfg'ye start CYLEX_LOGSYSTEM ekleyin.
3- Eğer meslek loglarının da çalışmasını istiyorsanız rar'ın içindeki MESLEK LOGLARI klasörünün içindekileri kullanmalısınız (biraz bilginiz varsa verdiğim mesleklere bakarak kendi mesleklerinize de uyarlayabilirsiniz.)
4- Son olarak rar'ın içindeki es_extended klasörünün içindeki main.lua'yı paketinizdeki es_extended/server içine atın. (aynı şekilde isterseniz kendiniz de uyarlayabilirsiniz.)


                                                                  NOT
Bu script fivemtürk'e özel yapılmıştır. İzinsiz bir şekilde başka bir yerde paylaşılması yasaktır.
CYLEX_LOGSYSTEM adını değiştirirseniz script çalışmayacaktır!
Eğer log sistemini SQL olarak kullanıcaksanız CYLEX_LOGSYSTEM içerisindeki data.sql'i yüklemeyi unutmayın.
Eğer discord olarak kullanacaksanız Config.lua içerisinden tüm WEBHOOK_LINK_HERE yazan yerleri kendi webhook'unuz ile değiştirin.


                                                                                                                                    DISCORD LOG
https://www.fivemturk.com/attachments/1582651498995-png.5427/

                                                                  SQL LOG
https://www.fivemturk.com/attachments/1582651543056-png.5428/
