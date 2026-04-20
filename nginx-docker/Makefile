.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make basic-up    - Start basic Nginx"
	@echo "  make basic-down  - Stop basic Nginx"
	@echo "  make ssl-up      - Start SSL Nginx"
	@echo "  make ssl-down    - Stop SSL Nginx"
	@echo "  make logs        - Show all logs"
	@echo "  make clean       - Clean all containers"

basic-up:
	cd nginx-docker && docker-compose up -d

basic-down:
	cd nginx-docker && docker-compose down

ssl-up:
	cd nginx-ssl-docker && docker-compose up -d

ssl-down:
	cd nginx-ssl-docker && docker-compose down

logs:
	cd nginx-docker && docker-compose logs -f &
	cd nginx-ssl-docker && docker-compose logs -f

clean:
	cd nginx-docker && docker-compose down -v
	cd nginx-ssl-docker && docker-compose down -v