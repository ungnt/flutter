import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class TrabalhoRoutes {
  static Router get router {
    final router = Router()
      ..get('/', (Request request) => Response.ok('{"status": "trabalho routes ok"}', headers: {'Content-Type': 'application/json'}))
      ..post('/', (Request request) => Response.ok('{"success": true}', headers: {'Content-Type': 'application/json'}));
    
    return router;
  }
}
