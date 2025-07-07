<script lang="ts">
import { onMount } from 'svelte';
let mapContainer: HTMLDivElement | null = null;

function loadKakaoMap() {
  if (!mapContainer) return;
  setTimeout(() => {
    const width = mapContainer.offsetWidth || 640;
    const height = Math.round(width * 9 / 16);
    mapContainer.innerHTML = '';
    if (!window['daum'] || !window['daum'].roughmap) {
      const script = document.createElement('script');
      script.src = 'https://ssl.daumcdn.net/dmaps/map_js_init/roughmapLoader.js';
      script.charset = 'UTF-8';
      script.onload = () => {
        window['daum'].roughmap.Lander({
          "timestamp": "1751856074840",
          "key": "58zax7beg8c",
          "mapWidth": width,
          "mapHeight": height,
          "container": mapContainer
        }).render();
      };
      document.body.appendChild(script);
    } else {
      window['daum'].roughmap.Lander({
        "timestamp": "1751856074840",
        "key": "58zax7beg8c",
        "mapWidth": width,
        "mapHeight": height,
        "container": mapContainer
      }).render();
    }
  }, 100);
}

onMount(() => {
  loadKakaoMap();
  window.addEventListener('resize', loadKakaoMap);
  return () => window.removeEventListener('resize', loadKakaoMap);
});
</script>

<div style="font:normal normal 400 12px/normal dotum, sans-serif; width:100%; max-width:640px; height:auto; color:#333; position:relative; margin: 0 auto;">
  <div style="height: auto;">
    <a href="https://map.kakao.com/?urlX=441634.99999999837&amp;urlY=1122092.9999999993&amp;itemId=11065168&amp;q=%EB%AF%BC%EB%93%A4%EB%A0%88%EC%9E%A5%EC%95%A0%EC%9D%B8%EC%9E%90%EB%A6%BD%EC%83%9D%ED%99%9C%EC%84%BC%ED%84%B0&amp;srcid=11065168&amp;map_type=TYPE_MAP&amp;from=roughmap" target="_blank">
      <img class="map" src="http://t1.daumcdn.net/roughmap/imgmap/19109b081db0478a7317dd79f87e583c4bcd462b459f7cd07633bd9ad8aa38b0" width="100%" height="auto" style="border:1px solid #ccc; max-width:638px;">
    </a>
  </div>
  <div style="overflow: hidden; padding: 7px 11px; border: 1px solid rgba(0, 0, 0, 0.1); border-radius: 0px 0px 2px 2px; background-color: rgb(249, 249, 249);">
    <a href="https://map.kakao.com" target="_blank" style="float: left;">
      <img src="//t1.daumcdn.net/localimg/localimages/07/2018/pc/common/logo_kakaomap.png" width="72" height="16" alt="카카오맵" style="display:block;width:72px;height:16px">
    </a>
    <div style="float: right; position: relative; top: 1px; font-size: 11px;">
      <a target="_blank" href="https://map.kakao.com/?from=roughmap&amp;srcid=11065168&amp;confirmid=11065168&amp;q=%EB%AF%BC%EB%93%A4%EB%A0%88%EC%9E%A5%EC%95%A0%EC%9D%B8%EC%9E%90%EB%A6%BD%EC%83%9D%ED%99%9C%EC%84%BC%ED%84%B0&amp;rv=on" style="float:left;height:15px;padding-top:1px;line-height:15px;color:#000;text-decoration: none;">로드뷰</a>
      <span style="width: 1px;padding: 0;margin: 0 8px 0 9px;height: 11px;vertical-align: top;position: relative;top: 2px;border-left: 1px solid #d0d0d0;float: left;"></span>
      <a target="_blank" href="https://map.kakao.com/?from=roughmap&amp;eName=%EB%AF%BC%EB%93%A4%EB%A0%88%EC%9E%A5%EC%95%A0%EC%9D%B8%EC%9E%90%EB%A6%BD%EC%83%9D%ED%99%9C%EC%84%BC%ED%84%B0&amp;eX=441634.99999999837&amp;eY=1122092.9999999993" style="float:left;height:15px;padding-top:1px;line-height:15px;color:#000;text-decoration: none;">길찾기</a>
      <span style="width: 1px;padding: 0;margin: 0 8px 0 9px;height: 11px;vertical-align: top;position: relative;top: 2px;border-left: 1px solid #d0d0d0;float: left;"></span>
      <a target="_blank" href="https://map.kakao.com?map_type=TYPE_MAP&amp;from=roughmap&amp;srcid=11065168&amp;itemId=11065168&amp;q=%EB%AF%BC%EB%93%A4%EB%A0%88%EC%9E%A5%EC%95%A0%EC%9D%B8%EC%9E%90%EB%A6%BD%EC%83%9D%ED%99%9C%EC%84%BC%ED%84%B0&amp;urlX=441634.99999999837&amp;urlY=1122092.9999999993" style="float:left;height:15px;padding-top:1px;line-height:15px;color:#000;text-decoration: none;">지도 크게 보기</a>
    </div>
  </div>
  <div>
    <span style="border-bottom:0px none #333333;position:absolute;left:-25px;top:-136px;width:0px;height:40px"></span>
  </div>
</div> 