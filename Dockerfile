FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN dart pub get
RUN mkdir -p bin && dart compile exe server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

ENV PORT=8080
EXPOSE 8080
CMD ["/app/bin/server"]
