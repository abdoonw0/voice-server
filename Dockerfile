FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8080
CMD ["/app/bin/server"]
