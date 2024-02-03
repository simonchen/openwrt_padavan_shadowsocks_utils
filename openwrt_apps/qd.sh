#!/bin/sh

url="https://www.ibmnb.com/qd.php?sign=56917374"
cookie="Hm_lvt_0be888c40cad775137497bbcd1ef1a6a=1698410220,1698455819,1698490330,1698542623;Uf3r_2132_editormode_e=1;Uf3r_2132_atlist=780962;Uf3r_2132_saltkey=qek0Ew1J;Uf3r_2132_lastvisit=1705189387;Uf3r_2132_atarget=1;Uf3r_2132_smile=1D2;Uf3r_2132_zqlj_sign_2042957=20240126;Uf3r_2132_auth=4d0cpDVwKOrzmTNozbYt7CTnack06kDsowCu%2BmQJJ8h5ZMuGv1m7vijhGm9ndONrsLrDv0wxzIf6%2F9N3ONDr1STyUIid;Uf3r_2132_lastcheckfeed=2042957%7C1706274194;Uf3r_2132_ulastactivity=96caQ7PoJ2TPK%2FITngvNzpB57xeeZpFqLF8r6nakIMg4bv%2FZEkdP;Uf3r_2132_visitedfid=88D59D1D8D54D41D2D165D60D86;Uf3r_2132_st_p=2042957%7C1706278854%7Cf16498c7b4bed247ac77af8cd29cfc09;Uf3r_2132_viewid=tid_2045805;Uf3r_2132_sid=naG99K;Uf3r_2132_lip=61.149.72.151%2C1706278846;Uf3r_2132_st_t=2042957%7C1706280054%7C5a5a0505436c51ac860209708582793a;Uf3r_2132_forum_lastvisit=D_86_1703206114D_60_1703854946D_165_1704202725D_2_1705758700D_41_1705797293D_54_1705833368D_8_1706241465D_1_1706274940D_59_1706277842D_88_1706280054;Uf3r_2132_onlineusernum=495;Uf3r_2132_sendmail=1;Uf3r_2132_checkpm=1;Uf3r_2132_lastact=1706280722%09plugin.php%09"
agent="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
cur_date=$(date +"%Y-%m-%d %H:%M:%S %A")

for i in {1..3}
do
  curl -v -c /root/cookie.txt -b /root/cookie.txt -b $cookie -H $agent $url 2>/dev/null | \
	sed -n '/.*<div id="messagetext" class="alert_info">/,/<\/div>/p' | sed -e 's/window.location.href/foo/g' | \
	sed -e 's/<div id="messagetext" class="alert_info">/<div style="font-size:12px;">/' | \
	sed -e 's/<p class="alert_btnleft">.*<\/p>//' | sed -e '$a'"<font size=1>$cur_date</font>" > /www/qd.htm &
done
