# LunarStack

**Astrofotografia da Lua por empilhamento, inteiramente no seu celular Android.**

O LunarStack transforma um vídeo tremido da Lua, gravado na mão, em uma única
fotografia nítida e sem ruído — a mesma técnica usada por ferramentas de
desktop como AutoStakkert e RegiStax: analisar todos os frames, manter só os
mais nítidos, alinhar com precisão sub-pixel e tirar a média. Tudo rodando
100% no aparelho, sem servidor e sem envio de dados.

**[⬇️ Baixar o APK (Releases)](https://github.com/AmaroMiranda/lunar-stack/releases)** —
na dúvida, use o `arm64-v8a` (celulares de 2017 em diante). Requer Android 10+.

## Recursos

- **Empilhar** — decodifica todos os frames do vídeo, mede a nitidez de cada um
  (variância do Laplaciano no plano de luminância), seleciona os N% melhores e
  os alinha com correlação de fase sub-pixel + refino afim por ECC antes de uma
  média ponderada por nitidez.
- **Estabilizar** — recodifica o vídeo com a Lua travada no centro do quadro
  (rastreamento por centroide de luminância, deslocamentos inteiros nos planos
  YUV, saída H.264/MP4). Sem áudio e sem filtros que destroem qualidade.
- **Estabilizar + empilhar** — para vídeos muito tremidos: os frames são salvos
  com a Lua pré-centralizada (deslocamento inteiro, **sem perda por
  recodificação**), garantindo que o registro fino do empilhador sempre convirja.
- **Nitidez multi-escala opcional** — wavelets à trous / starlet (estilo
  RegiStax), só na luminância, calibrada para continuar parecendo fotografia.
- **Modo cru (Empilhamento cru)** — só alinha e tira a média; nenhum ajuste de
  nitidez ou tom.
- **Exportação** — PNG / JPEG para a galeria, ou TIFF 16-bit (profundidade
  tonal real do acumulador float) em `Downloads/LunarStack` para edição
  externa.
- Interface escura, pensada para astrofotografia, em português (pt-BR).

## Como funciona

| Etapa | Onde | O que acontece |
|---|---|---|
| Decodificação e análise | Kotlin (`MediaExtractor` + `MediaCodec`, modo ByteBuffer com YUV flexível) | cada frame é decodificado uma vez e recebe nota de nitidez no plano Y |
| Seleção de frames | Dart | os N% melhores por nota, limitados por um máximo configurável |
| Extração | Kotlin | só os frames selecionados são decodificados de novo e salvos como PNG sem perdas (conversão BT.601 ciente da faixa de cor), com a codificação dos PNGs em um grupo de threads |
| Registro e empilhamento | C++ / OpenCV via `dart:ffi` | correlação de fase (sinal resolvido por NCC) + afim por ECC por frame, interpolação cúbica, acumulação float ponderada por nitidez, corte automático |
| Pós-processamento | C++ | nitidez wavelet opcional, saída PNG/JPEG/TIFF 16-bit |
| Estabilização | Kotlin | decodifica → centroide → deslocamento inteiro dos planos YUV → codificação H.264 → empacotamento MP4, com as capacidades do codificador consultadas por aparelho |

Decisões de projeto que valem conhecer antes de contribuir (todas medidas em
vídeos reais — os comentários em `native/engine/src/engine.cpp` documentam os
números):

- A **seleção de frames** é a alavanca dominante de nitidez, não um alinhamento
  mais sofisticado.
- O *double-stack reference* do AutoStakkert e o alinhamento multi-ponto foram
  ambos implementados, medidos e **revertidos** — em vídeos estáveis de celular
  eles comprovadamente suavizam o resultado.
- O MediaCodec é usado exclusivamente em modo ByteBuffer +
  `COLOR_FormatYUV420Flexible`: decodificar para um `ImageReader` crasha em
  aparelhos cujo decodificador de hardware emite formatos tiled proprietários.

## Compilando

Requisitos:

- Flutter (canal estável) com as ferramentas de Android
- Android SDK + NDK (o projeto usa a versão de NDK fixada pelo Flutter)
- [OpenCV Android SDK](https://opencv.org/releases/) (4.x)

Aponte o build para o seu OpenCV Android SDK, via propriedade Gradle em
`~/.gradle/gradle.properties`:

```properties
lunarstack.opencvDir=/caminho/para/OpenCV-android-sdk/sdk/native/jni
```

ou via variável de ambiente:

```bash
export OPENCV_ANDROID_SDK=/caminho/para/OpenCV-android-sdk
```

Depois:

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

Instale o `app-arm64-v8a-release.apk` em um aparelho real. O engine nativo
(`libastro_engine.so`) é compilado automaticamente pelo Gradle a partir de
`native/CMakeLists.txt`; uma CLI standalone (`astro_stack_cli`), para iterar no
algoritmo via `adb`, é compilada junto no modo debug (nunca vai para o APK).

## Estrutura do projeto

```
lib/                  App Flutter (Riverpod + go_router + freezed)
  core/native/        bindings dart:ffi + ponte MethodChannel
  features/           uma pasta por tela/fluxo
android/app/src/main/kotlin/
  SequentialFrameExtractor.kt   decodificação/análise/extração via MediaCodec
  VideoStabilizer.kt            estabilizador por centroide (decodifica→desloca→recodifica)
native/
  engine/             engine C++ OpenCV (API C plana, consumida via FFI)
  tools/test_stack.cpp          CLI via adb para experimentos A/B controlados
```

## Contribuindo

Mudanças de qualidade no pipeline de empilhamento precisam vir com medição A/B
controlada (mesmos frames de entrada, uma variável por vez — largura de borda
do limbo e variância do Laplaciano são as métricas da casa;
`native/tools/test_stack.cpp` existe exatamente para isso). PRs que deixam a
imagem "melhor aos olhos" sem números vão receber pedido de números.

## Licença

Copyright 2026 Amaro Miranda

Licenciado sob a [Apache License 2.0](LICENSE).

O OpenCV é usado sob sua própria licença Apache 2.0.
