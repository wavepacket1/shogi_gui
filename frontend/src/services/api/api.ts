/* eslint-disable */
/* tslint:disable */
// @ts-nocheck
/*
 * ---------------------------------------------------------------
 * ## THIS FILE WAS GENERATED VIA SWAGGER-TYPESCRIPT-API        ##
 * ##                                                           ##
 * ## AUTHOR: acacode                                           ##
 * ## SOURCE: https://github.com/acacode/swagger-typescript-api ##
 * ---------------------------------------------------------------
 */

export interface Game {
  game_id: number;
  status: "active" | "finished" | "pause";
  board_id: number;
}

export interface Error {
  error?: string;
}

export type QueryParamsType = Record<string | number, any>;
export type ResponseFormat = keyof Omit<Body, "body" | "bodyUsed">;

export interface FullRequestParams extends Omit<RequestInit, "body"> {
  /** set parameter to `true` for call `securityWorker` for this request */
  secure?: boolean;
  /** request path */
  path: string;
  /** content type of request body */
  type?: ContentType;
  /** query params */
  query?: QueryParamsType;
  /** format of response (i.e. response.json() -> format: "json") */
  format?: ResponseFormat;
  /** request body */
  body?: unknown;
  /** base url */
  baseUrl?: string;
  /** request cancellation token */
  cancelToken?: CancelToken;
}

export type RequestParams = Omit<FullRequestParams, "body" | "method" | "query" | "path">;

export interface ApiConfig<SecurityDataType = unknown> {
  baseUrl?: string;
  baseApiParams?: Omit<RequestParams, "baseUrl" | "cancelToken" | "signal">;
  securityWorker?: (securityData: SecurityDataType | null) => Promise<RequestParams | void> | RequestParams | void;
  customFetch?: typeof fetch;
}

export interface HttpResponse<D extends unknown, E extends unknown = unknown> extends Response {
  data: D;
  error: E;
}

type CancelToken = Symbol | string | number;

export enum ContentType {
  Json = "application/json",
  FormData = "multipart/form-data",
  UrlEncoded = "application/x-www-form-urlencoded",
  Text = "text/plain",
}

export class HttpClient<SecurityDataType = unknown> {
  public baseUrl: string = "http://localhost:3000";
  private securityData: SecurityDataType | null = null;
  private securityWorker?: ApiConfig<SecurityDataType>["securityWorker"];
  private abortControllers = new Map<CancelToken, AbortController>();
  private customFetch = (...fetchParams: Parameters<typeof fetch>) => fetch(...fetchParams);

  private baseApiParams: RequestParams = {
    credentials: "same-origin",
    headers: {},
    redirect: "follow",
    referrerPolicy: "no-referrer",
  };

  constructor(apiConfig: ApiConfig<SecurityDataType> = {}) {
    Object.assign(this, apiConfig);
  }

  public setSecurityData = (data: SecurityDataType | null) => {
    this.securityData = data;
  };

  protected encodeQueryParam(key: string, value: any) {
    const encodedKey = encodeURIComponent(key);
    return `${encodedKey}=${encodeURIComponent(typeof value === "number" ? value : `${value}`)}`;
  }

  protected addQueryParam(query: QueryParamsType, key: string) {
    return this.encodeQueryParam(key, query[key]);
  }

  protected addArrayQueryParam(query: QueryParamsType, key: string) {
    const value = query[key];
    return value.map((v: any) => this.encodeQueryParam(key, v)).join("&");
  }

  protected toQueryString(rawQuery?: QueryParamsType): string {
    const query = rawQuery || {};
    const keys = Object.keys(query).filter((key) => "undefined" !== typeof query[key]);
    return keys
      .map((key) => (Array.isArray(query[key]) ? this.addArrayQueryParam(query, key) : this.addQueryParam(query, key)))
      .join("&");
  }

  protected addQueryParams(rawQuery?: QueryParamsType): string {
    const queryString = this.toQueryString(rawQuery);
    return queryString ? `?${queryString}` : "";
  }

  private contentFormatters: Record<ContentType, (input: any) => any> = {
    [ContentType.Json]: (input: any) =>
      input !== null && (typeof input === "object" || typeof input === "string") ? JSON.stringify(input) : input,
    [ContentType.Text]: (input: any) => (input !== null && typeof input !== "string" ? JSON.stringify(input) : input),
    [ContentType.FormData]: (input: any) =>
      Object.keys(input || {}).reduce((formData, key) => {
        const property = input[key];
        formData.append(
          key,
          property instanceof Blob
            ? property
            : typeof property === "object" && property !== null
              ? JSON.stringify(property)
              : `${property}`,
        );
        return formData;
      }, new FormData()),
    [ContentType.UrlEncoded]: (input: any) => this.toQueryString(input),
  };

  protected mergeRequestParams(params1: RequestParams, params2?: RequestParams): RequestParams {
    return {
      ...this.baseApiParams,
      ...params1,
      ...(params2 || {}),
      headers: {
        ...(this.baseApiParams.headers || {}),
        ...(params1.headers || {}),
        ...((params2 && params2.headers) || {}),
      },
    };
  }

  protected createAbortSignal = (cancelToken: CancelToken): AbortSignal | undefined => {
    if (this.abortControllers.has(cancelToken)) {
      const abortController = this.abortControllers.get(cancelToken);
      if (abortController) {
        return abortController.signal;
      }
      return void 0;
    }

    const abortController = new AbortController();
    this.abortControllers.set(cancelToken, abortController);
    return abortController.signal;
  };

  public abortRequest = (cancelToken: CancelToken) => {
    const abortController = this.abortControllers.get(cancelToken);

    if (abortController) {
      abortController.abort();
      this.abortControllers.delete(cancelToken);
    }
  };

  public request = async <T = any, E = any>({
    body,
    secure,
    path,
    type,
    query,
    format,
    baseUrl,
    cancelToken,
    ...params
  }: FullRequestParams): Promise<HttpResponse<T, E>> => {
    const secureParams =
      ((typeof secure === "boolean" ? secure : this.baseApiParams.secure) &&
        this.securityWorker &&
        (await this.securityWorker(this.securityData))) ||
      {};
    const requestParams = this.mergeRequestParams(params, secureParams);
    const queryString = query && this.toQueryString(query);
    const payloadFormatter = this.contentFormatters[type || ContentType.Json];
    const responseFormat = format || requestParams.format;

    return this.customFetch(`${baseUrl || this.baseUrl || ""}${path}${queryString ? `?${queryString}` : ""}`, {
      ...requestParams,
      headers: {
        ...(requestParams.headers || {}),
        ...(type && type !== ContentType.FormData ? { "Content-Type": type } : {}),
      },
      signal: (cancelToken ? this.createAbortSignal(cancelToken) : requestParams.signal) || null,
      body: typeof body === "undefined" || body === null ? null : payloadFormatter(body),
    }).then(async (response) => {
      const r = response.clone() as HttpResponse<T, E>;
      r.data = null as unknown as T;
      r.error = null as unknown as E;

      const data = !responseFormat
        ? r
        : await response[responseFormat]()
            .then((data) => {
              if (r.ok) {
                r.data = data;
              } else {
                r.error = data;
              }
              return r;
            })
            .catch((e) => {
              r.error = e;
              return r;
            });

      if (cancelToken) {
        this.abortControllers.delete(cancelToken);
      }

      if (!response.ok) throw data;
      return data;
    });
  };
}

/**
 * @title Shogi API V1
 * @version v1
 * @baseUrl http://localhost:3000
 *
 * 将棋アプリケーションのAPI仕様
 */
export class Api<SecurityDataType extends unknown> extends HttpClient<SecurityDataType> {
  api = {
    /**
     * No description
     *
     * @tags BoardHistories
     * @name V1GamesBoardHistoriesList
     * @summary 局面履歴の取得
     * @request GET:/api/v1/games/{game_id}/board_histories
     */
    v1GamesBoardHistoriesList: (
      gameId: number,
      query?: {
        /** 分岐名（デフォルト: main） */
        branch?: string;
      },
      params: RequestParams = {},
    ) =>
      this.request<
        {
          id?: number;
          game_id?: number;
          sfen?: string;
          move_number?: number;
          branch?: string;
          /** 前局面からの指し手情報（SFEN形式）。例：7g7f, P*3d, 8h2b+ */
          move_sfen?: string | null;
          /** 棋譜表記（例：「▲7六歩」「△8四銀」）。日本語形式で表示された棋譜。 */
          notation?: string | null;
          /** @format date-time */
          created_at?: string;
          /** @format date-time */
          updated_at?: string;
        }[],
        {
          error?: string;
          status?: number;
        }
      >({
        path: `/api/v1/games/${gameId}/board_histories`,
        method: "GET",
        query: query,
        format: "json",
        ...params,
      }),

    /**
     * No description
     *
     * @tags BoardHistories
     * @name V1GamesBoardHistoriesBranchesList
     * @summary 分岐リストの取得
     * @request GET:/api/v1/games/{game_id}/board_histories/branches
     */
    v1GamesBoardHistoriesBranchesList: (gameId: number, params: RequestParams = {}) =>
      this.request<
        {
          branches?: string[];
        },
        {
          error?: string;
          status?: number;
        }
      >({
        path: `/api/v1/games/${gameId}/board_histories/branches`,
        method: "GET",
        format: "json",
        ...params,
      }),

    /**
     * No description
     *
     * @tags BoardHistories
     * @name V1GamesNavigateToCreate
     * @summary 指定した手数の局面に移動
     * @request POST:/api/v1/games/{game_id}/navigate_to/{move_number}
     */
    v1GamesNavigateToCreate: (
      gameId: number,
      moveNumber: number,
      query?: {
        /** 分岐名（デフォルト: main） */
        branch?: string;
      },
      params: RequestParams = {},
    ) =>
      this.request<
        {
          game_id?: number;
          board_id?: number;
          move_number?: number;
          sfen?: string;
          /** 前局面からの指し手情報（SFEN形式） */
          move_sfen?: string | null;
          /** 棋譜表記（日本語形式） */
          notation?: string | null;
        },
        {
          error?: string;
          status?: number;
        }
      >({
        path: `/api/v1/games/${gameId}/navigate_to/${moveNumber}`,
        method: "POST",
        query: query,
        format: "json",
        ...params,
      }),

    /**
     * No description
     *
     * @tags BoardHistories
     * @name V1GamesSwitchBranchCreate
     * @summary 分岐切り替え
     * @request POST:/api/v1/games/{game_id}/switch_branch/{branch_name}
     */
    v1GamesSwitchBranchCreate: (gameId: number, branchName: string, params: RequestParams = {}) =>
      this.request<
        {
          game_id?: number;
          branch?: string;
          current_move_number?: number;
          /** 前局面からの指し手情報（SFEN形式） */
          move_sfen?: string | null;
          /** 棋譜表記（日本語形式） */
          notation?: string | null;
        },
        {
          error?: string;
          status?: number;
        }
      >({
        path: `/api/v1/games/${gameId}/switch_branch/${branchName}`,
        method: "POST",
        format: "json",
        ...params,
      }),

    /**
     * No description
     *
     * @tags Boards
     * @name V1BoardsDetail
     * @summary ボードの取得
     * @request GET:/api/v1/boards/{id}
     */
    v1BoardsDetail: (id: number, params: RequestParams = {}) =>
      this.request<
        {
          sfen: string;
          legal_flag: boolean;
        },
        {
          status: string;
          message: string;
        }
      >({
        path: `/api/v1/boards/${id}`,
        method: "GET",
        format: "json",
        ...params,
      }),

    /**
     * No description
     *
     * @tags Boards
     * @name V1BoardsDefaultList
     * @summary デフォルトボードの取得
     * @request GET:/api/v1/boards/default
     */
    v1BoardsDefaultList: (params: RequestParams = {}) =>
      this.request<
        {
          sfen: string;
          legal_flag: boolean;
        },
        any
      >({
        path: `/api/v1/boards/default`,
        method: "GET",
        format: "json",
        ...params,
      }),

    /**
     * No description
     *
     * @tags Games
     * @name V1GamesCreate
     * @summary ゲームを作成する
     * @request POST:/api/v1/games
     */
    v1GamesCreate: (
      data: {
        status: "active" | "finished" | "pause";
      },
      params: RequestParams = {},
    ) =>
      this.request<
        {
          game_id: number;
          status: "active" | "finished" | "pause";
          board_id: number;
        },
        {
          error?: string;
        }
      >({
        path: `/api/v1/games`,
        method: "POST",
        body: data,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),

    /**
     * No description
     *
     * @tags Games
     * @name V1GamesBoardsNyugyokuDeclarationCreate
     * @summary 入玉宣言を行う
     * @request POST:/api/v1/games/{game_id}/boards/{board_id}/nyugyoku_declaration
     */
    v1GamesBoardsNyugyokuDeclarationCreate: (gameId: number, boardId: number, params: RequestParams = {}) =>
      this.request<
        {
          status: "success" | "failed";
          game_id: number;
          board_id: number;
        },
        {
          status: string;
          message: string;
        }
      >({
        path: `/api/v1/games/${gameId}/boards/${boardId}/nyugyoku_declaration`,
        method: "POST",
        format: "json",
        ...params,
      }),

    /**
     * No description
     *
     * @tags Games
     * @name V1GamesIdResignCreate
     * @summary 投了を行う
     * @request POST:/api/v1/games/:id/resign
     */
    v1GamesIdResignCreate: (id: number, params: RequestParams = {}) =>
      this.request<
        {
          status: "success" | "failed";
          game_status: "finished";
          winner: string;
          ended_at: string;
        },
        {
          status: string;
          message: string;
        }
      >({
        path: `/api/v1/games/${id}/resign`,
        method: "POST",
        format: "json",
        ...params,
      }),

    /**
     * No description
     *
     * @tags Moves
     * @name V1GamesBoardsMovePartialUpdate
     * @summary 駒の移動API
     * @request PATCH:/api/v1/games/{game_id}/boards/{board_id}/move
     */
    v1GamesBoardsMovePartialUpdate: (
      gameId: number,
      boardId: number,
      data: {
        /**
         * 指し手の表記
         * @example "7g7f"
         */
        move: string;
      },
      query?: {
        /** 現在の手数（分岐作成用） */
        move_number?: number;
        /** 現在の分岐名（分岐作成用） */
        branch?: string;
      },
      params: RequestParams = {},
    ) =>
      this.request<
        {
          /** @example true */
          status?: boolean;
          /** @example false */
          is_checkmate?: boolean;
          /** @example false */
          is_repetition?: boolean;
          /** @example false */
          is_repetition_check?: boolean;
          /** @example 123 */
          board_id?: number;
          /** @example "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0" */
          sfen?: string;
          /** @example 1 */
          move_number?: number;
          /** @example "main" */
          branch?: string;
          /**
           * 前局面からの指し手情報（SFEN形式）
           * @example "7g7f"
           */
          move_sfen?: string;
          /**
           * 棋譜表記（日本語形式）
           * @example "▲7六歩"
           */
          notation?: string;
        },
        {
          /** @example false */
          status?: boolean;
          /** @example "Invalid move: 8h2b+" */
          message?: string;
          /** @example 123 */
          board_id?: number;
          /** @example "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0" */
          sfen?: string;
        }
      >({
        path: `/api/v1/games/${gameId}/boards/${boardId}/move`,
        method: "PATCH",
        query: query,
        body: data,
        type: ContentType.Json,
        format: "json",
        ...params,
      }),
  };
}
